{{ config(
    materialized='table',
    cluster_by=['npi_number'],
    tags=['gold', 'provider', 'dim', 'network']
) }}

with affiliations as (
    select * from {{ ref('int_provider_network__affiliations') }}
),

dim as (
    select
        affiliation_sk as provider_network_sk,
        network_affiliation_id,
        npi_number,
        network_name,
        network_tier,
        participation_status,
        effective_date,
        termination_date,
        par_agreement_type,
        is_currently_participating,
        case
            when termination_date is not null then
                datediff('day', effective_date, termination_date)
            else
                datediff('day', effective_date, current_date())
        end as tenure_days,
        _source_loaded_at,
        current_timestamp() as _dbt_loaded_at
    from affiliations
)

select * from dim
