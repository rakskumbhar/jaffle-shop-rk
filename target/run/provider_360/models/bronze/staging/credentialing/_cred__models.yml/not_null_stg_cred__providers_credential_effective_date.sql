select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select credential_effective_date
from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
where credential_effective_date is null



      
    ) dbt_internal_test