select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select facility_name
from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where facility_name is null



      
    ) dbt_internal_test