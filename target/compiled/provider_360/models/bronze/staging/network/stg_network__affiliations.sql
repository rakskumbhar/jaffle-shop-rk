with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.network_affiliations_raw
),

renamed as (
    select
        network_affiliation_id::varchar   as network_affiliation_id,
        npi_number::varchar(10)           as npi_number,
        network_name::varchar             as network_name,
        network_tier::varchar             as network_tier,
        participation_status::varchar     as participation_status,
        effective_date::date              as effective_date,
        termination_date::date            as termination_date,
        par_agreement_type::varchar       as par_agreement_type,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed