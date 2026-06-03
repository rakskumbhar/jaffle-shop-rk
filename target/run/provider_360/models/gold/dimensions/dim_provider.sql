
  
    

        create or replace transient table SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
          
  (
    provider_sk varchar not null,
    npi_number varchar(10) not null,
    valid_from timestamp_ntz not null,
    valid_to timestamp_ntz not null,
    is_current boolean,
    first_name varchar,
    last_name varchar,
    full_name varchar,
    credentials varchar,
    gender_code varchar,
    gender_description varchar,
    entity_type_code varchar,
    entity_type varchar,
    is_sole_proprietor varchar,
    npi_status varchar,
    npi_status_description varchar,
    enumeration_date date,
    deactivation_date date,
    reactivation_date date,
    is_npi_active boolean,
    specialty_code varchar,
    specialty_description varchar,
    primary_taxonomy_code varchar,
    board_certification varchar,
    credential_status varchar,
    credential_effective_date date,
    credential_expiry_date date,
    is_credentialed boolean,
    facility_name varchar,
    address_line_1 varchar,
    address_line_2 varchar,
    city varchar,
    state_code varchar,
    zip_code varchar,
    phone_number varchar,
    is_accepting_patients boolean,
    provider_status varchar,
    is_fully_active boolean,
    _record_updated_at timestamp_ntz,
    _dbt_loaded_at timestamp_ltz
    
    )

          
        
         as
        (select * from (
              
    select provider_sk, npi_number, valid_from, valid_to, is_current, first_name, last_name, full_name, credentials, gender_code, gender_description, entity_type_code, entity_type, is_sole_proprietor, npi_status, npi_status_description, enumeration_date, deactivation_date, reactivation_date, is_npi_active, specialty_code, specialty_description, primary_taxonomy_code, board_certification, credential_status, credential_effective_date, credential_expiry_date, is_credentialed, facility_name, address_line_1, address_line_2, city, state_code, zip_code, phone_number, is_accepting_patients, provider_status, is_fully_active, _record_updated_at, _dbt_loaded_at
    from (
        

with snapshot as (
    select * from SNOWFLAKE_LEARNING_DB.SNAPSHOTS.snp_provider_attributes
),

dim as (
    select
        md5(coalesce(cast(npi_number as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast(dbt_valid_from as varchar), '_dbt_utils_surrogate_key_null_')) as provider_sk,

        npi_number,

        dbt_valid_from::timestamp_ntz as valid_from,
        coalesce(
            dbt_valid_to,
            '9999-12-31'::timestamp_ntz
        ) as valid_to,
        (dbt_valid_to is null)::boolean as is_current,

        first_name,
        last_name,
        trim(first_name || ' ' || last_name) as full_name,
        credentials,
        gender_code,
        case gender_code
            when 'M' then 'Male'
            when 'F' then 'Female'
            else 'Unknown'
        end as gender_description,
        entity_type_code,
        case entity_type_code
            when '1' then 'Individual'
            when '2' then 'Organization'
            else 'Unknown'
        end as entity_type,
        is_sole_proprietor,

        npi_status,
        case npi_status
            when 'A' then 'Active'
            when 'D' then 'Deactivated'
            when 'R' then 'Retired'
            else 'Unknown'
        end as npi_status_description,
        enumeration_date,
        deactivation_date,
        reactivation_date,
        (npi_status = 'A'
            and deactivation_date is null)::boolean as is_npi_active,

        specialty_code,
        specialty_description,
        primary_taxonomy_code,
        board_certification,
        credential_status,
        credential_effective_date,
        credential_expiry_date,
        (
            credential_status = 'ACTIVE'
            and (credential_expiry_date is null
                 or credential_expiry_date >= current_date())
        )::boolean as is_credentialed,

        facility_name,
        address_line_1,
        address_line_2,
        city,
        state_code,
        zip_code,
        phone_number,
        is_accepting_patients,
        provider_status,

        (
            npi_status = 'A'
            and deactivation_date is null
            and credential_status = 'ACTIVE'
            and (credential_expiry_date is null
                 or credential_expiry_date >= current_date())
            and provider_status = 'ACTIVE'
        )::boolean as is_fully_active,

        dbt_updated_at as _record_updated_at,
        current_timestamp() as _dbt_loaded_at

    from snapshot
)

select * from dim
    ) as model_subq
              ) order by (npi_number, is_current)
        );
      alter  table SNOWFLAKE_LEARNING_DB.GOLD.dim_provider cluster by (npi_number, is_current);
  