

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