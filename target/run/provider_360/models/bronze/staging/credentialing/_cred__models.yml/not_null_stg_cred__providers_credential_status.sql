select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select credential_status
from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
where credential_status is null



      
    ) dbt_internal_test