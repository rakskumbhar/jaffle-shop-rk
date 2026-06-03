select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    quality_metric_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.GOLD.fct_quality_metrics
where quality_metric_sk is not null
group by quality_metric_sk
having count(*) > 1



      
    ) dbt_internal_test