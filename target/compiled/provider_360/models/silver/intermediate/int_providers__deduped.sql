

with unified as (
    select * from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified
    
        where _unified_at > (select max(_unified_at) from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__deduped)
    
),

deduped as (
    select
        md5(coalesce(cast(npi_number as varchar), '_dbt_utils_surrogate_key_null_')) as provider_dedup_key,
        *,
        row_number() over (
            partition by npi_number
            order by _source_loaded_at desc
        ) as _dedup_rank,
        'NPI_REGISTRY' as source_system
    from unified
)

select * from deduped
where _dedup_rank = 1