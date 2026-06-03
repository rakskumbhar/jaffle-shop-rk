
  create or replace   view SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
  
    
    
(
  
    "CREDENTIALING_ID" COMMENT $$Unique identifier from credentialing system$$, 
  
    "NPI_NUMBER" COMMENT $$10-digit National Provider Identifier for cross-reference$$, 
  
    "SPECIALTY_CODE" COMMENT $$Provider specialty classification code$$, 
  
    "SPECIALTY_DESCRIPTION" COMMENT $$$$, 
  
    "BOARD_CERTIFICATION" COMMENT $$$$, 
  
    "CREDENTIAL_STATUS" COMMENT $$Current credentialing status$$, 
  
    "CREDENTIAL_EFFECTIVE_DATE" COMMENT $$Date credential became effective$$, 
  
    "CREDENTIAL_EXPIRY_DATE" COMMENT $$Date credential expires$$, 
  
    "PRIMARY_TAXONOMY_CODE" COMMENT $$$$, 
  
    "_SOURCE_LOADED_AT" COMMENT $$Timestamp when record was loaded into raw ingestion$$
  
)

   as (
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
  );

