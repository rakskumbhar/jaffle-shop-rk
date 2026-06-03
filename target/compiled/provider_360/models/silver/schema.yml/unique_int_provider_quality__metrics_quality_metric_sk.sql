
    
    

select
    quality_metric_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics
where quality_metric_sk is not null
group by quality_metric_sk
having count(*) > 1


