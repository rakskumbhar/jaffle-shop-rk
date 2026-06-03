select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select npi_status
from SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
where npi_status is null



      
    ) dbt_internal_test