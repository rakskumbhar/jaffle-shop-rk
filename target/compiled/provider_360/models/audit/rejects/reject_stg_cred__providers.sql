

with source as (
    select
        provider_id::varchar              as credentialing_id,
        npi_number::varchar(10)           as npi_number,
        credential_status::varchar        as credential_status,
        credential_effective_date::date   as credential_effective_date,
        credential_expiry_date::date      as credential_expiry_date,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_credentials_raw
    
        where _loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_cred__providers)
    
),

rejected as (
    select
        md5(coalesce(cast(credentialing_id as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(_source_loaded_at as varchar), '_dbt_utils_surrogate_key_null_')) as reject_id,
        'stg_cred__providers' as source_model,
        npi_number,
        
array_compact(array_construct(
    case when npi_number is null then 'NPI_NUMBER_NULL' end,
    case when length(npi_number) != 10 then 'NPI_INVALID_LENGTH' end,
    case when credential_status not in ('ACTIVE', 'EXPIRED', 'PENDING', 'REVOKED') and credential_status is not null then 'INVALID_CREDENTIAL_STATUS' end,
    case when credential_effective_date is null then 'EFFECTIVE_DATE_NULL' end,
    case when credential_expiry_date < credential_effective_date then 'EXPIRY_BEFORE_EFFECTIVE' end
))
 as reject_reasons,
        _source_loaded_at,
        'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
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