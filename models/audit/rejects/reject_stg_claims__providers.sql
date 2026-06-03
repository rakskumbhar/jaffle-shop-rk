{{ config(
    materialized='incremental',
    unique_key='reject_id',
    incremental_strategy='append',
    schema='REJECT',
    tags=['audit', 'reject']
) }}

with source as (
    select
        claim_id::varchar                 as claim_id,
        npi_number::varchar(10)           as npi_number,
        service_date::date                as service_date,
        allowed_amount::number(12,2)      as allowed_amount,
        paid_amount::number(12,2)         as paid_amount,
        claim_status::varchar             as claim_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from {{ source('claims', 'claims_raw') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

rejected as (
    select
        {{ generate_surrogate_key(['claim_id', '_source_loaded_at']) }} as reject_id,
        'stg_claims__providers' as source_model,
        npi_number,
        {{ build_reject_reason_array([
            {"condition": "claim_id is null", "reason": "CLAIM_ID_NULL"},
            {"condition": "npi_number is null", "reason": "NPI_NUMBER_NULL"},
            {"condition": "length(npi_number) != 10", "reason": "NPI_INVALID_LENGTH"},
            {"condition": "service_date is null", "reason": "SERVICE_DATE_NULL"},
            {"condition": "service_date > current_date()", "reason": "FUTURE_SERVICE_DATE"},
            {"condition": "allowed_amount < 0", "reason": "NEGATIVE_ALLOWED_AMOUNT"},
            {"condition": "paid_amount < 0", "reason": "NEGATIVE_PAID_AMOUNT"},
            {"condition": "claim_status not in ('PAID', 'DENIED', 'PENDING', 'ADJUSTED') and claim_status is not null", "reason": "INVALID_CLAIM_STATUS"}
        ]) }} as reject_reasons,
        _source_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        claim_id is null
        or npi_number is null
        or length(npi_number) != 10
        or service_date is null
        or service_date > current_date()
        or allowed_amount < 0
        or paid_amount < 0
        or (claim_status not in ('PAID', 'DENIED', 'PENDING', 'ADJUSTED') and claim_status is not null)
)

select * from rejected
