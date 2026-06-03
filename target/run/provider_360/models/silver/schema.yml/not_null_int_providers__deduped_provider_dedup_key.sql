select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select provider_dedup_key
from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__deduped
where provider_dedup_key is null



      
    ) dbt_internal_test