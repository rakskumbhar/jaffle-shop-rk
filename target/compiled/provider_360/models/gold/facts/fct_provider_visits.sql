

with claims as (
    select * from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
    
        where _source_loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits)
    
),

facts as (
    select
        md5(coalesce(cast(claim_id as varchar), '_dbt_utils_surrogate_key_null_')) as visit_sk,
        claim_id,
        npi_number,
        patient_id,
        service_date,
        procedure_code,
        diagnosis_code,
        allowed_amount,
        paid_amount,
        claim_status,
        network_status,
        case
            when claim_status = 'PAID' then paid_amount
            else 0
        end as net_paid_amount,
        case
            when claim_status = 'PAID' then allowed_amount - paid_amount
            else 0
        end as patient_responsibility,
        _source_loaded_at,
        current_timestamp() as _dbt_loaded_at
    from claims
)

select * from facts