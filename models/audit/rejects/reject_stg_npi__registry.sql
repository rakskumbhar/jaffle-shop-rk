{{ config(
    materialized='incremental',
    unique_key='reject_id',
    incremental_strategy='append',
    schema='REJECT',
    tags=['audit', 'reject']
) }}

with source as (
    select
        npi_number::varchar(10)           as npi_number,
        provider_first_name::varchar      as first_name,
        provider_last_name_legal::varchar  as last_name,
        status::varchar(1)                as npi_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from {{ source('npi_registry', 'npi_raw') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

rejected as (
    select
        {{ generate_surrogate_key(['npi_number', '_source_loaded_at']) }} as reject_id,
        'stg_npi__registry' as source_model,
        npi_number,
        {{ build_reject_reason_array([
            {"condition": "npi_number is null", "reason": "NPI_NUMBER_NULL"},
            {"condition": "length(npi_number) != 10", "reason": "NPI_INVALID_LENGTH"},
            {"condition": "try_to_number(npi_number) is null and npi_number is not null", "reason": "NPI_NON_NUMERIC"},
            {"condition": "first_name is null", "reason": "FIRST_NAME_NULL"},
            {"condition": "last_name is null", "reason": "LAST_NAME_NULL"},
            {"condition": "npi_status not in ('A', 'D', 'R') and npi_status is not null", "reason": "INVALID_NPI_STATUS"}
        ]) }} as reject_reasons,
        _source_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        npi_number is null
        or length(npi_number) != 10
        or (try_to_number(npi_number) is null and npi_number is not null)
        or first_name is null
        or last_name is null
        or (npi_status not in ('A', 'D', 'R') and npi_status is not null)
)

select * from rejected
