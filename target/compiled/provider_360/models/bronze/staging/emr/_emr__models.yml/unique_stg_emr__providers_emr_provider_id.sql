
    
    

select
    emr_provider_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where emr_provider_id is not null
group by emr_provider_id
having count(*) > 1


