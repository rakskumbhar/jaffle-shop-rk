select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        benchmark_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.GOLD.fct_quality_metrics
    group by benchmark_status

)

select *
from all_values
where value_field not in (
    'ABOVE_BENCHMARK','NEAR_BENCHMARK','BELOW_BENCHMARK'
)



      
    ) dbt_internal_test