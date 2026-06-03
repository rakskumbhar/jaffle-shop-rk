

with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW.stg_network__affiliations
    
        where _source_loaded_at > (select max(_source_loaded_at) from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations)
    
),

enriched as (
    select
        md5(coalesce(cast(network_affiliation_id as varchar), '_dbt_utils_surrogate_key_null_')) as affiliation_sk,
        s.*,
        case
            when s.participation_status = 'PARTICIPATING'
                 and (s.termination_date is null or s.termination_date > current_date())
            then true
            else false
        end as is_currently_participating,
        current_timestamp() as _enriched_at
    from source s
)

select * from enriched