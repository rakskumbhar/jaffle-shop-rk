select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select effective_date
from SNOWFLAKE_LEARNING_DB.RAW.stg_network__affiliations
where effective_date is null



      
    ) dbt_internal_test