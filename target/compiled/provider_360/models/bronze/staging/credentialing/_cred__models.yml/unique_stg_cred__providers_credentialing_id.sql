
    
    

select
    credentialing_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
where credentialing_id is not null
group by credentialing_id
having count(*) > 1


