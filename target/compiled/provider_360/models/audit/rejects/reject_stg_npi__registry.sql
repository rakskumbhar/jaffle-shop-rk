

with source as (
    select
        npi_number::varchar(10)           as npi_number,
        provider_first_name::varchar      as first_name,
        provider_last_name_legal::varchar  as last_name,
        status::varchar(1)                as npi_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.npi_raw
    
        where _loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_npi__registry)
    
),

rejected as (
    select
        md5(coalesce(cast(npi_number as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(_source_loaded_at as varchar), '_dbt_utils_surrogate_key_null_')) as reject_id,
        'stg_npi__registry' as source_model,
        npi_number,
        
array_compact(array_construct(
    case when npi_number is null then 'NPI_NUMBER_NULL' end,
    case when length(npi_number) != 10 then 'NPI_INVALID_LENGTH' end,
    case when try_to_number(npi_number) is null and npi_number is not null then 'NPI_NON_NUMERIC' end,
    case when first_name is null then 'FIRST_NAME_NULL' end,
    case when last_name is null then 'LAST_NAME_NULL' end,
    case when npi_status not in ('A', 'D', 'R') and npi_status is not null then 'INVALID_NPI_STATUS' end
))
 as reject_reasons,
        _source_loaded_at,
        'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
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