with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_master_raw
),

renamed as (
    select
        provider_id::varchar              as emr_provider_id,
        npi_number::varchar(10)           as npi_number,
        facility_name::varchar            as facility_name,
        address_line_1::varchar           as address_line_1,
        address_line_2::varchar           as address_line_2,
        city::varchar                     as city,
        state_code::varchar(2)            as state_code,
        zip_code::varchar(10)             as zip_code,
        phone_number::varchar(15)         as phone_number,
        accepting_new_patients::boolean   as is_accepting_patients,
        provider_status::varchar          as provider_status,
        updated_at::timestamp_ntz         as updated_at,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed