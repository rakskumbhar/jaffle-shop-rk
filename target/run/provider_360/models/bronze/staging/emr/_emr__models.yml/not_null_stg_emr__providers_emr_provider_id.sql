select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select emr_provider_id
from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where emr_provider_id is null



      
    ) dbt_internal_test