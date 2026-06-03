
    
    

select
    run_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.AUDIT.audit__run_metadata
where run_id is not null
group by run_id
having count(*) > 1


