
    
    

select
    network_affiliation_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.RAW.stg_network__affiliations
where network_affiliation_id is not null
group by network_affiliation_id
having count(*) > 1


