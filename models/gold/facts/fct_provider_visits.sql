{{ config(
    materialized='incremental',
    unique_key='visit_sk',
    incremental_strategy='merge',
    on_schema_change='fail',
    cluster_by=['npi_number', 'service_date'],
    tags=['gold', 'provider', 'fact']
) }}

with claims as (
    select * from {{ ref('stg_claims__providers') }}
    {% if is_incremental() %}
        where _source_loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

facts as (
    select
        {{ generate_surrogate_key(['claim_id']) }} as visit_sk,
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
