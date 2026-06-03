select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select paid_amount
from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits
where paid_amount is null



      
    ) dbt_internal_test