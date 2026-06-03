select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        performance_tier as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.GOLD.fct_quality_metrics
    group by performance_tier

)

select *
from all_values
where value_field not in (
    'EXCELLENT','GOOD','FAIR','NEEDS_IMPROVEMENT'
)



      
    ) dbt_internal_test