select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select measure_name
from SNOWFLAKE_LEARNING_DB.GOLD.fct_quality_metrics
where measure_name is null



      
    ) dbt_internal_test