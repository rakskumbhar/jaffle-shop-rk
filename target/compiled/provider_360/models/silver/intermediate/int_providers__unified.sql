

with npi as (
    select * from SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
    
        where _source_loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified)
    
),

cred as (
    select * from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
    where credential_status = 'ACTIVE'
    qualify row_number() over (
        partition by npi_number
        order by credential_effective_date desc
    ) = 1
),

emr as (
    select * from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
    qualify row_number() over (
        partition by npi_number
        order by updated_at desc
    ) = 1
),

unified as (
    select
        n.npi_number,
        n.first_name,
        n.last_name,
        n.credentials,
        n.gender_code,
        n.entity_type_code,
        n.is_sole_proprietor,
        n.npi_status,
        n.enumeration_date,
        n.deactivation_date,
        n.reactivation_date,
        c.specialty_code,
        c.specialty_description,
        c.primary_taxonomy_code,
        c.board_certification,
        c.credential_status,
        c.credential_effective_date,
        c.credential_expiry_date,
        e.facility_name,
        e.address_line_1,
        e.address_line_2,
        e.city,
        e.state_code,
        e.zip_code,
        e.phone_number,
        e.is_accepting_patients,
        e.provider_status,
        greatest(
            n._source_loaded_at,
            coalesce(c._source_loaded_at, '1900-01-01'::timestamp_ntz),
            coalesce(e._source_loaded_at, '1900-01-01'::timestamp_ntz)
        ) as _source_loaded_at,
        current_timestamp() as _unified_at
    from npi n
    left join cred c on n.npi_number = c.npi_number
    left join emr  e on n.npi_number = e.npi_number
)

select * from unified