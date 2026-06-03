select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select run_id
from SNOWFLAKE_LEARNING_DB.AUDIT.audit__run_metadata
where run_id is null



      
    ) dbt_internal_test