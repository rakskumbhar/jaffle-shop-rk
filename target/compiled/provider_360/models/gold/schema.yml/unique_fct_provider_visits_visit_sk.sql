
    
    

select
    visit_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits
where visit_sk is not null
group by visit_sk
having count(*) > 1


