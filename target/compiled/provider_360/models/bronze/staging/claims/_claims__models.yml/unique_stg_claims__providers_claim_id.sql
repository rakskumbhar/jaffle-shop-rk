
    
    

select
    claim_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
where claim_id is not null
group by claim_id
having count(*) > 1


