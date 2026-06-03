select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select allowed_amount
from SNOWFLAKE_LEARNING_DB.GOLD.fct_provider_visits
where allowed_amount is null



      
    ) dbt_internal_test