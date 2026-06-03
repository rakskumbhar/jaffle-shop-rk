{{ config(
    materialized='incremental',
    unique_key='reject_id',
    incremental_strategy='append',
    schema='REJECT',
    tags=['audit', 'reject']
) }}

with source as (
    select
        provider_id::varchar              as emr_provider_id,
        npi_number::varchar(10)           as npi_number,
        facility_name::varchar            as facility_name,
        city::varchar                     as city,
        state_code::varchar(2)            as state_code,
        zip_code::varchar(10)             as zip_code,
        provider_status::varchar          as provider_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from {{ source('emr', 'provider_master_raw') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

rejected as (
    select
        {{ generate_surrogate_key(['emr_provider_id', '_source_loaded_at']) }} as reject_id,
        'stg_emr__providers' as source_model,
        npi_number,
        {{ build_reject_reason_array([
            {"condition": "npi_number is null", "reason": "NPI_NUMBER_NULL"},
            {"condition": "length(npi_number) != 10", "reason": "NPI_INVALID_LENGTH"},
            {"condition": "facility_name is null", "reason": "FACILITY_NAME_NULL"},
            {"condition": "state_code is null", "reason": "STATE_CODE_NULL"},
            {"condition": "length(state_code) != 2 and state_code is not null", "reason": "INVALID_STATE_CODE_LENGTH"},
            {"condition": "zip_code is null", "reason": "ZIP_CODE_NULL"}
        ]) }} as reject_reasons,
        _source_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        npi_number is null
        or length(npi_number) != 10
        or facility_name is null
        or state_code is null
        or (length(state_code) != 2 and state_code is not null)
        or zip_code is null
)

select * from rejected
