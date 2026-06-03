

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
    from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_master_raw
    
        where _loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_emr__providers)
    
),

rejected as (
    select
        md5(coalesce(cast(emr_provider_id as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(_source_loaded_at as varchar), '_dbt_utils_surrogate_key_null_')) as reject_id,
        'stg_emr__providers' as source_model,
        npi_number,
        
array_compact(array_construct(
    case when npi_number is null then 'NPI_NUMBER_NULL' end,
    case when length(npi_number) != 10 then 'NPI_INVALID_LENGTH' end,
    case when facility_name is null then 'FACILITY_NAME_NULL' end,
    case when state_code is null then 'STATE_CODE_NULL' end,
    case when length(state_code) != 2 and state_code is not null then 'INVALID_STATE_CODE_LENGTH' end,
    case when zip_code is null then 'ZIP_CODE_NULL' end
))
 as reject_reasons,
        _source_loaded_at,
        'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
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