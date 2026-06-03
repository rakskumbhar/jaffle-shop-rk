select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select provider_sk
from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
where provider_sk is null



      
    ) dbt_internal_test