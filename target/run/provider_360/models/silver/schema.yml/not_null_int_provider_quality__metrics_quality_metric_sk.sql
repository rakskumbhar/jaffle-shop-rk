select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select quality_metric_sk
from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics
where quality_metric_sk is null



      
    ) dbt_internal_test