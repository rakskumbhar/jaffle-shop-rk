
    
    

select
    affiliation_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations
where affiliation_sk is not null
group by affiliation_sk
having count(*) > 1


