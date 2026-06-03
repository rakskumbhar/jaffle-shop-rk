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