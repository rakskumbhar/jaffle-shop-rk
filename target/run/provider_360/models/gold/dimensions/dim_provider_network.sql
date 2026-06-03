
  
    

        create or replace transient table SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network
          
  (
    provider_network_sk varchar not null,
    network_affiliation_id varchar,
    npi_number varchar(10) not null,
    network_name varchar not null,
    network_tier varchar,
    participation_status varchar,
    effective_date date,
    termination_date date,
    par_agreement_type varchar,
    is_currently_participating boolean,
    tenure_days number(18,0),
    _source_loaded_at timestamp_ntz,
    _dbt_loaded_at timestamp_ltz
    
    )

          
        
         as
        (select * from (
              
    select provider_network_sk, network_affiliation_id, npi_number, network_name, network_tier, participation_status, effective_date, termination_date, par_agreement_type, is_currently_participating, tenure_days, _source_loaded_at, _dbt_loaded_at
    from (
        

with affiliations as (
    select * from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations
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
    ) as model_subq
              ) order by (npi_number)
        );
      alter  table SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network cluster by (npi_number);
  