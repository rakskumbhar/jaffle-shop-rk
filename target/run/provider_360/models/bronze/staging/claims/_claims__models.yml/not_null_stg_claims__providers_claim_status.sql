select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select claim_status
from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
where claim_status is null



      
    ) dbt_internal_test