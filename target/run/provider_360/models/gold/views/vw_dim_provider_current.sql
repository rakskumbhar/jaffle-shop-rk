
  create or replace   view SNOWFLAKE_LEARNING_DB.GOLD.vw_dim_provider_current
  
    
    
(
  
    "PROVIDER_SK" COMMENT $$$$, 
  
    "NPI_NUMBER" COMMENT $$$$, 
  
    "VALID_FROM" COMMENT $$$$, 
  
    "VALID_TO" COMMENT $$$$, 
  
    "IS_CURRENT" COMMENT $$$$, 
  
    "FIRST_NAME" COMMENT $$$$, 
  
    "LAST_NAME" COMMENT $$$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "CREDENTIALS" COMMENT $$$$, 
  
    "GENDER_CODE" COMMENT $$$$, 
  
    "GENDER_DESCRIPTION" COMMENT $$$$, 
  
    "ENTITY_TYPE_CODE" COMMENT $$$$, 
  
    "ENTITY_TYPE" COMMENT $$$$, 
  
    "IS_SOLE_PROPRIETOR" COMMENT $$$$, 
  
    "NPI_STATUS" COMMENT $$$$, 
  
    "NPI_STATUS_DESCRIPTION" COMMENT $$$$, 
  
    "ENUMERATION_DATE" COMMENT $$$$, 
  
    "DEACTIVATION_DATE" COMMENT $$$$, 
  
    "REACTIVATION_DATE" COMMENT $$$$, 
  
    "IS_NPI_ACTIVE" COMMENT $$$$, 
  
    "SPECIALTY_CODE" COMMENT $$$$, 
  
    "SPECIALTY_DESCRIPTION" COMMENT $$$$, 
  
    "PRIMARY_TAXONOMY_CODE" COMMENT $$$$, 
  
    "BOARD_CERTIFICATION" COMMENT $$$$, 
  
    "CREDENTIAL_STATUS" COMMENT $$$$, 
  
    "CREDENTIAL_EFFECTIVE_DATE" COMMENT $$$$, 
  
    "CREDENTIAL_EXPIRY_DATE" COMMENT $$$$, 
  
    "IS_CREDENTIALED" COMMENT $$$$, 
  
    "FACILITY_NAME" COMMENT $$$$, 
  
    "ADDRESS_LINE_1" COMMENT $$$$, 
  
    "ADDRESS_LINE_2" COMMENT $$$$, 
  
    "CITY" COMMENT $$$$, 
  
    "STATE_CODE" COMMENT $$$$, 
  
    "ZIP_CODE" COMMENT $$$$, 
  
    "PHONE_NUMBER" COMMENT $$$$, 
  
    "IS_ACCEPTING_PATIENTS" COMMENT $$$$, 
  
    "PROVIDER_STATUS" COMMENT $$$$, 
  
    "IS_FULLY_ACTIVE" COMMENT $$$$, 
  
    "_RECORD_UPDATED_AT" COMMENT $$$$, 
  
    "_DBT_LOADED_AT" COMMENT $$$$
  
)

   as (
    

select * from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
where is_current = true
  );

