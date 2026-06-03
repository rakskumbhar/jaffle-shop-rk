select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select summary_id
from SNOWFLAKE_LEARNING_DB.AUDIT.audit__reject_summary
where summary_id is null



      
    ) dbt_internal_test