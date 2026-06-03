select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select network_status
from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
where network_status is null



      
    ) dbt_internal_test