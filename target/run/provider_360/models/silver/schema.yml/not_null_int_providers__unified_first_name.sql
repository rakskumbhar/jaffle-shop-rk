select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select first_name
from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified
where first_name is null



      
    ) dbt_internal_test