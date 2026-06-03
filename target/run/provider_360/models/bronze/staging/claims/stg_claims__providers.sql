
  create or replace   view SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
  
    
    
(
  
    "CLAIM_ID" COMMENT $$Unique claim identifier from source system$$, 
  
    "NPI_NUMBER" COMMENT $$Rendering provider 10-digit NPI$$, 
  
    "PATIENT_ID" COMMENT $$Patient identifier$$, 
  
    "SERVICE_DATE" COMMENT $$Date of service$$, 
  
    "PROCEDURE_CODE" COMMENT $$$$, 
  
    "DIAGNOSIS_CODE" COMMENT $$$$, 
  
    "ALLOWED_AMOUNT" COMMENT $$Contracted allowed amount for the service$$, 
  
    "PAID_AMOUNT" COMMENT $$Amount actually paid$$, 
  
    "CLAIM_STATUS" COMMENT $$Current claim adjudication status$$, 
  
    "NETWORK_STATUS" COMMENT $$Whether claim is in-network or out-of-network$$, 
  
    "_SOURCE_LOADED_AT" COMMENT $$Timestamp when record was loaded into raw ingestion$$
  
)

   as (
    with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.claims_raw
),

renamed as (
    select
        claim_id::varchar                 as claim_id,
        npi_number::varchar(10)           as npi_number,
        patient_id::varchar               as patient_id,
        service_date::date                as service_date,
        procedure_code::varchar           as procedure_code,
        diagnosis_code::varchar           as diagnosis_code,
        allowed_amount::number(12,2)      as allowed_amount,
        paid_amount::number(12,2)         as paid_amount,
        claim_status::varchar             as claim_status,
        network_status::varchar           as network_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed
  );

