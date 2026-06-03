{{ config(
    materialized='incremental',
    unique_key='reject_id',
    incremental_strategy='append',
    schema='REJECT',
    tags=['audit', 'reject']
) }}

with source as (
    select
        network_affiliation_id::varchar   as network_affiliation_id,
        npi_number::varchar(10)           as npi_number,
        network_name::varchar             as network_name,
        participation_status::varchar     as participation_status,
        effective_date::date              as effective_date,
        termination_date::date            as termination_date,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from {{ source('network', 'network_affiliations_raw') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

rejected as (
    select
        {{ generate_surrogate_key(['network_affiliation_id', '_source_loaded_at']) }} as reject_id,
        'stg_network__affiliations' as source_model,
        npi_number,
        {{ build_reject_reason_array([
            {"condition": "network_affiliation_id is null", "reason": "AFFILIATION_ID_NULL"},
            {"condition": "npi_number is null", "reason": "NPI_NUMBER_NULL"},
            {"condition": "length(npi_number) != 10", "reason": "NPI_INVALID_LENGTH"},
            {"condition": "network_name is null", "reason": "NETWORK_NAME_NULL"},
            {"condition": "participation_status not in ('PARTICIPATING', 'TERMINATED', 'SUSPENDED') and participation_status is not null", "reason": "INVALID_PARTICIPATION_STATUS"},
            {"condition": "effective_date is null", "reason": "EFFECTIVE_DATE_NULL"},
            {"condition": "termination_date < effective_date", "reason": "TERMINATION_BEFORE_EFFECTIVE"}
        ]) }} as reject_reasons,
        _source_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        network_affiliation_id is null
        or npi_number is null
        or length(npi_number) != 10
        or network_name is null
        or (participation_status not in ('PARTICIPATING', 'TERMINATED', 'SUSPENDED') and participation_status is not null)
        or effective_date is null
        or termination_date < effective_date
)

select * from rejected
