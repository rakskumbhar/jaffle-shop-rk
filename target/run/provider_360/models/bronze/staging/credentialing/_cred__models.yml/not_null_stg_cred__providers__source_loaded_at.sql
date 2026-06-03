select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select _source_loaded_at
from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
where _source_loaded_at is null



      
    ) dbt_internal_test