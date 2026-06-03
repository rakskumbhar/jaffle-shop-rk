

with source as (
    select
        claim_id::varchar                 as claim_id,
        npi_number::varchar(10)           as npi_number,
        service_date::date                as service_date,
        allowed_amount::number(12,2)      as allowed_amount,
        paid_amount::number(12,2)         as paid_amount,
        claim_status::varchar             as claim_status,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.claims_raw
    
        where _loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_claims__providers)
    
),

rejected as (
    select
        md5(coalesce(cast(claim_id as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(_source_loaded_at as varchar), '_dbt_utils_surrogate_key_null_')) as reject_id,
        'stg_claims__providers' as source_model,
        npi_number,
        
array_compact(array_construct(
    case when claim_id is null then 'CLAIM_ID_NULL' end,
    case when npi_number is null then 'NPI_NUMBER_NULL' end,
    case when length(npi_number) != 10 then 'NPI_INVALID_LENGTH' end,
    case when service_date is null then 'SERVICE_DATE_NULL' end,
    case when service_date > current_date() then 'FUTURE_SERVICE_DATE' end,
    case when allowed_amount < 0 then 'NEGATIVE_ALLOWED_AMOUNT' end,
    case when paid_amount < 0 then 'NEGATIVE_PAID_AMOUNT' end,
    case when claim_status not in ('PAID', 'DENIED', 'PENDING', 'ADJUSTED') and claim_status is not null then 'INVALID_CLAIM_STATUS' end
))
 as reject_reasons,
        _source_loaded_at,
        'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
        current_timestamp() as rejected_at
    from source
    where
        claim_id is null
        or npi_number is null
        or length(npi_number) != 10
        or service_date is null
        or service_date > current_date()
        or allowed_amount < 0
        or paid_amount < 0
        or (claim_status not in ('PAID', 'DENIED', 'PENDING', 'ADJUSTED') and claim_status is not null)
)

select * from rejected