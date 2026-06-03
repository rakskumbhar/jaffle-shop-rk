select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select visit_sk
from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits
where visit_sk is null



      
    ) dbt_internal_test