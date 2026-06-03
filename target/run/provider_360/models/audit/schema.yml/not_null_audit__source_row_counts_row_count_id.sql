select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select row_count_id
from SNOWFLAKE_LEARNING_DB.AUDIT.audit__source_row_counts
where row_count_id is null



      
    ) dbt_internal_test