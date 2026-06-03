select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select npi_status
from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified
where npi_status is null



      
    ) dbt_internal_test