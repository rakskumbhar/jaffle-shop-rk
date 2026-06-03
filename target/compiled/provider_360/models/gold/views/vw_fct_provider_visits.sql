

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