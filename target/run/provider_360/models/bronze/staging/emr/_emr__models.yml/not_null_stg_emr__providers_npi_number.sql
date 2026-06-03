select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select npi_number
from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where npi_number is null



      
    ) dbt_internal_test