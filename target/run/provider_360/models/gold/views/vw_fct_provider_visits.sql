
  create or replace   view SNOWFLAKE_LEARNING_DB.GOLD.vw_fct_provider_visits
  
    
    
(
  
    "VISIT_SK" COMMENT $$$$, 
  
    "CLAIM_ID" COMMENT $$$$, 
  
    "NPI_NUMBER" COMMENT $$$$, 
  
    "PATIENT_ID" COMMENT $$$$, 
  
    "SERVICE_DATE" COMMENT $$$$, 
  
    "PROCEDURE_CODE" COMMENT $$$$, 
  
    "DIAGNOSIS_CODE" COMMENT $$$$, 
  
    "ALLOWED_AMOUNT" COMMENT $$$$, 
  
    "PAID_AMOUNT" COMMENT $$$$, 
  
    "NET_PAID_AMOUNT" COMMENT $$$$, 
  
    "PATIENT_RESPONSIBILITY" COMMENT $$$$, 
  
    "CLAIM_STATUS" COMMENT $$$$, 
  
    "NETWORK_STATUS" COMMENT $$$$, 
  
    "_DBT_LOADED_AT" COMMENT $$$$
  
)

   as (
    

select
    v.visit_sk,
    v.claim_id,
    v.npi_number,
    v.patient_id,
    v.service_date,
    v.procedure_code,
    v.diagnosis_code,
    v.allowed_amount,
    v.paid_amount,
    v.net_paid_amount,
    v.patient_responsibility,
    v.claim_status,
    v.network_status,
    v._dbt_loaded_at
from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits v
  );

