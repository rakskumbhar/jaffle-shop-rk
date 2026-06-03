select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    row_count_id as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.AUDIT.audit__source_row_counts
where row_count_id is not null
group by row_count_id
having count(*) > 1



      
    ) dbt_internal_test