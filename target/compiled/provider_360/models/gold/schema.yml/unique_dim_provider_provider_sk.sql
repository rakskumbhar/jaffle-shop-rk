
    
    

select
    provider_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
where provider_sk is not null
group by provider_sk
having count(*) > 1


