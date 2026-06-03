select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select credentialing_id
from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
where credentialing_id is null



      
    ) dbt_internal_test