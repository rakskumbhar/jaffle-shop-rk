{{ config(
    materialized='table',
    cluster_by=['npi_number'],
    tags=['gold', 'provider', 'obt']
) }}

with providers as (
    select * from {{ ref('int_providers__deduped') }}
),

visits_agg as (
    select
        npi_number,
        count(distinct claim_id) as total_claims,
        count(distinct patient_id) as unique_patients,
        sum(allowed_amount) as total_allowed_amount,
        sum(paid_amount) as total_paid_amount,
        min(service_date) as first_service_date,
        max(service_date) as last_service_date,
        sum(case when claim_status = 'DENIED' then 1 else 0 end) as denied_claims,
        round(
            sum(case when claim_status = 'DENIED' then 1 else 0 end)::float
            / nullif(count(*), 0) * 100, 2
        ) as denial_rate_pct
    from {{ ref('stg_claims__providers') }}
    group by 1
),


network_agg as (
    select
        npi_number,
        count(distinct network_name) as total_networks,
        sum(case when is_currently_participating then 1 else 0 end) as active_networks,
        listagg(case when is_currently_participating then network_name end, ', ')
            within group (order by network_name) as active_network_list
    from {{ ref('int_provider_network__affiliations') }}
    group by 1
),

summary as (
    select
        p.npi_number,
        p.first_name,
        p.last_name,
        trim(p.first_name || ' ' || p.last_name) as full_name,
        p.credentials,
        p.gender_code,
        p.entity_type_code,
        p.npi_status,
        p.specialty_code,
        p.specialty_description,
        p.primary_taxonomy_code,
        p.board_certification,
        p.credential_status,
        p.credential_effective_date,
        p.credential_expiry_date,
        p.facility_name,
        p.city,
        p.state_code,
        p.zip_code,
        p.phone_number,
        p.is_accepting_patients,
        p.provider_status,

        (
            p.npi_status = 'A'
            and p.deactivation_date is null
            and p.credential_status = 'ACTIVE'
            and (p.credential_expiry_date is null
                 or p.credential_expiry_date >= current_date())
            and p.provider_status = 'ACTIVE'
        )::boolean as is_fully_active,

        coalesce(v.total_claims, 0) as total_claims,
        coalesce(v.unique_patients, 0) as unique_patients,
        coalesce(v.total_allowed_amount, 0) as total_allowed_amount,
        coalesce(v.total_paid_amount, 0) as total_paid_amount,
        v.first_service_date,
        v.last_service_date,
        coalesce(v.denied_claims, 0) as denied_claims,
        coalesce(v.denial_rate_pct, 0) as denial_rate_pct,


        coalesce(n.total_networks, 0) as total_networks,
        coalesce(n.active_networks, 0) as active_networks,
        n.active_network_list,

        current_timestamp() as _dbt_loaded_at

    from providers p
    left join visits_agg v on p.npi_number = v.npi_number
    left join network_agg n on p.npi_number = n.npi_number
)

select * from summary
