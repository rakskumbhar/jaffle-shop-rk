select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select patient_id
from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
where patient_id is null



      
    ) dbt_internal_test