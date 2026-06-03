select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select reject_id
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_emr__providers
where reject_id is null



      
    ) dbt_internal_test