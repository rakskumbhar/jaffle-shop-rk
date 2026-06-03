select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select total_claims
from SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary
where total_claims is null



      
    ) dbt_internal_test