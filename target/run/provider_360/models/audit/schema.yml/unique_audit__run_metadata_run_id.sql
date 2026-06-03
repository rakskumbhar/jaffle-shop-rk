select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    run_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.AUDIT.audit__run_metadata
where run_id is not null
group by run_id
having count(*) > 1



      
    ) dbt_internal_test