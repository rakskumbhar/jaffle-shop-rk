select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    provider_dedup_key as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__deduped
where provider_dedup_key is not null
group by provider_dedup_key
having count(*) > 1



      
    ) dbt_internal_test