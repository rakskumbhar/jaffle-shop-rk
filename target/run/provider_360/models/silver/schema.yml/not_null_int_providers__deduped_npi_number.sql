select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select npi_number
from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__deduped
where npi_number is null



      
    ) dbt_internal_test