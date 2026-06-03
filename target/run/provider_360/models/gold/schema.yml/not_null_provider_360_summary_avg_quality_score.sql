select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select avg_quality_score
from SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary
where avg_quality_score is null



      
    ) dbt_internal_test