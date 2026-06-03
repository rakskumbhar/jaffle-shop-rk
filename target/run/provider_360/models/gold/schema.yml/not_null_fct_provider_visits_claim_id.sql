select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select claim_id
from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits
where claim_id is null



      
    ) dbt_internal_test