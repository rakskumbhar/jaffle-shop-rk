select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where city is null



      
    ) dbt_internal_test