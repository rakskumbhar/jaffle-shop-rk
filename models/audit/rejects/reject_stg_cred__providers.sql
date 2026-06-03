{{ config(
    materialized='incremental',
    unique_key='reject_id',
    incremental_strategy='append',
    schema='REJECT',
    tags=['audit', 'reject']
) }}

with source as (
    select
        provider_id::varchar              as credentialing_id,
        npi_number::varchar(10)           as npi_number,
        credential_status::varchar        as credential_status,
        credential_effective_date::date   as credential_effective_date,
        credential_expiry_date::date      as credential_expiry_date,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from {{ source('credentialing', 'provider_credentials_raw') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

rejected as (
    select
        {{ generate_surrogate_key(['credentialing_id', '_source_loaded_at']) }} as reject_id,
        'stg_cred__providers' as source_model,
        npi_number,
        {{ build_reject_reason_array([
            {"condition": "npi_number is null", "reason": "NPI_NUMBER_NULL"},
            {"condition": "length(npi_number) != 10", "reason": "NPI_INVALID_LENGTH"},
            {"condition": "credential_status not in ('ACTIVE', 'EXPIRED', 'PENDING', 'REVOKED') and credential_status is not null", "reason": "INVALID_CREDENTIAL_STATUS"},
            {"condition": "credential_effective_date is null", "reason": "EFFECTIVE_DATE_NULL"},
            {"condition": "credential_expiry_date < credential_effective_date", "reason": "EXPIRY_BEFORE_EFFECTIVE"}
        ]) }} as reject_reasons,
        _source_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        npi_number is null
        or length(npi_number) != 10
        or (credential_status not in ('ACTIVE', 'EXPIRED', 'PENDING', 'REVOKED') and credential_status is not null)
        or credential_effective_date is null
        or credential_expiry_date < credential_effective_date
)

select * from rejected
