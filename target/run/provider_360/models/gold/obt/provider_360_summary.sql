
  
    

        create or replace transient table SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary
          
  (
    npi_number varchar(10) not null,
    first_name varchar,
    last_name varchar,
    full_name varchar,
    credentials varchar,
    gender_code varchar,
    entity_type_code varchar,
    npi_status varchar,
    specialty_code varchar,
    specialty_description varchar,
    primary_taxonomy_code varchar,
    board_certification varchar,
    credential_status varchar,
    credential_effective_date date,
    credential_expiry_date date,
    facility_name varchar,
    city varchar,
    state_code varchar,
    zip_code varchar,
    phone_number varchar,
    is_accepting_patients boolean,
    provider_status varchar,
    is_fully_active boolean not null,
    total_claims number(18,0) not null,
    unique_patients number(18,0),
    total_allowed_amount number(18,2),
    total_paid_amount number(18,2),
    first_service_date date,
    last_service_date date,
    denied_claims number(18,0),
    denial_rate_pct float,
    total_networks number(18,0),
    active_networks number(18,0),
    active_network_list varchar,
    _dbt_loaded_at timestamp_ltz
    
    )

          
        
         as
        (select * from (
              
    select npi_number, first_name, last_name, full_name, credentials, gender_code, entity_type_code, npi_status, specialty_code, specialty_description, primary_taxonomy_code, board_certification, credential_status, credential_effective_date, credential_expiry_date, facility_name, city, state_code, zip_code, phone_number, is_accepting_patients, provider_status, is_fully_active, total_claims, unique_patients, total_allowed_amount, total_paid_amount, first_service_date, last_service_date, denied_claims, denial_rate_pct, total_networks, active_networks, active_network_list, _dbt_loaded_at
    from (
        

with providers as (
    select * from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__deduped
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
    from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
    group by 1
),


network_agg as (
    select
        npi_number,
        count(distinct network_name) as total_networks,
        sum(case when is_currently_participating then 1 else 0 end) as active_networks,
        listagg(case when is_currently_participating then network_name end, ', ')
            within group (order by network_name) as active_network_list
    from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations
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
    ) as model_subq
              ) order by (npi_number)
        );
      alter  table SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary cluster by (npi_number);
  