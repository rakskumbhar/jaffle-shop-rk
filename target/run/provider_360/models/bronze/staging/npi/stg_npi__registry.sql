
  create or replace   view SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
  
    
    
(
  
    "NPI_NUMBER" COMMENT $$10-digit National Provider Identifier$$, 
  
    "FIRST_NAME" COMMENT $$Provider first name$$, 
  
    "LAST_NAME" COMMENT $$Provider last name$$, 
  
    "CREDENTIALS" COMMENT $$$$, 
  
    "GENDER_CODE" COMMENT $$$$, 
  
    "ENTITY_TYPE_CODE" COMMENT $$$$, 
  
    "IS_SOLE_PROPRIETOR" COMMENT $$$$, 
  
    "ENUMERATION_DATE" COMMENT $$Date NPI was first assigned$$, 
  
    "LAST_UPDATE_DATE" COMMENT $$$$, 
  
    "DEACTIVATION_DATE" COMMENT $$$$, 
  
    "REACTIVATION_DATE" COMMENT $$$$, 
  
    "NPI_STATUS" COMMENT $$NPI lifecycle status: A=Active, D=Deactivated, R=Retired$$, 
  
    "_SOURCE_LOADED_AT" COMMENT $$Timestamp when record was loaded into raw ingestion$$
  
)

   as (
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
  );

