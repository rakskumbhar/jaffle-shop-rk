select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select enumeration_date
from SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
where enumeration_date is null



      
    ) dbt_internal_test