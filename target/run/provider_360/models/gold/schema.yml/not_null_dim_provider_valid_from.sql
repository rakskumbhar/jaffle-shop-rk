select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select valid_from
from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
where valid_from is null



      
    ) dbt_internal_test