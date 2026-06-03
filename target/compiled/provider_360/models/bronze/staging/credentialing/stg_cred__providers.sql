with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_credentials_raw
),

renamed as (
    select
        provider_id::varchar              as credentialing_id,
        npi_number::varchar(10)           as npi_number,
        specialty_code::varchar           as specialty_code,
        specialty_description::varchar    as specialty_description,
        board_certification::varchar      as board_certification,
        credential_status::varchar        as credential_status,
        credential_effective_date::date   as credential_effective_date,
        credential_expiry_date::date      as credential_expiry_date,
        primary_taxonomy_code::varchar    as primary_taxonomy_code,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed