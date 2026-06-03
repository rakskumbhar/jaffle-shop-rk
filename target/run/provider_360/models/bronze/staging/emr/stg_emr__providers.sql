
  create or replace   view SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
  
    
    
(
  
    "EMR_PROVIDER_ID" COMMENT $$Unique provider ID from EMR system$$, 
  
    "NPI_NUMBER" COMMENT $$10-digit National Provider Identifier for cross-reference$$, 
  
    "FACILITY_NAME" COMMENT $$Name of the practice/facility$$, 
  
    "ADDRESS_LINE_1" COMMENT $$Practice street address$$, 
  
    "ADDRESS_LINE_2" COMMENT $$$$, 
  
    "CITY" COMMENT $$Practice city$$, 
  
    "STATE_CODE" COMMENT $$2-letter US state code$$, 
  
    "ZIP_CODE" COMMENT $$Practice ZIP code$$, 
  
    "PHONE_NUMBER" COMMENT $$Practice phone number$$, 
  
    "IS_ACCEPTING_PATIENTS" COMMENT $$Whether provider is accepting new patients$$, 
  
    "PROVIDER_STATUS" COMMENT $$EMR system provider status$$, 
  
    "UPDATED_AT" COMMENT $$$$, 
  
    "_SOURCE_LOADED_AT" COMMENT $$Timestamp when record was loaded into raw ingestion$$
  
)

   as (
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
  );

