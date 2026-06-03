with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.npi_raw
),

renamed as (
    select
        npi_number::varchar(10)           as npi_number,
        provider_first_name::varchar      as first_name,
        provider_last_name_legal::varchar as last_name,
        provider_credential_text::varchar as credentials,
        provider_gender_code::varchar(1)  as gender_code,
        entity_type_code::varchar(1)      as entity_type_code,
        sole_proprietor::varchar(1)       as is_sole_proprietor,
        enumeration_date::date            as enumeration_date,
        last_update_date::date            as last_update_date,
        npi_deactivation_date::date       as deactivation_date,
        npi_reactivation_date::date       as reactivation_date,
        status::varchar(1)                as npi_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed