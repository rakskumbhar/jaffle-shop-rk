select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select is_fully_active
from SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary
where is_fully_active is null



      
    ) dbt_internal_test