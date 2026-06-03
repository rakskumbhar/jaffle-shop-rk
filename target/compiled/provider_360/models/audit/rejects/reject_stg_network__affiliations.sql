

with source as (
    select
        network_affiliation_id::varchar   as network_affiliation_id,
        npi_number::varchar(10)           as npi_number,
        network_name::varchar             as network_name,
        participation_status::varchar     as participation_status,
        effective_date::date              as effective_date,
        termination_date::date            as termination_date,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.network_affiliations_raw
    
        where _loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_network__affiliations)
    
),

rejected as (
    select
        md5(coalesce(cast(network_affiliation_id as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(_source_loaded_at as varchar), '_dbt_utils_surrogate_key_null_')) as reject_id,
        'stg_network__affiliations' as source_model,
        npi_number,
        
array_compact(array_construct(
    case when network_affiliation_id is null then 'AFFILIATION_ID_NULL' end,
    case when npi_number is null then 'NPI_NUMBER_NULL' end,
    case when length(npi_number) != 10 then 'NPI_INVALID_LENGTH' end,
    case when network_name is null then 'NETWORK_NAME_NULL' end,
    case when participation_status not in ('PARTICIPATING', 'TERMINATED', 'SUSPENDED') and participation_status is not null then 'INVALID_PARTICIPATION_STATUS' end,
    case when effective_date is null then 'EFFECTIVE_DATE_NULL' end,
    case when termination_date < effective_date then 'TERMINATION_BEFORE_EFFECTIVE' end
))
 as reject_reasons,
        _source_loaded_at,
        'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
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