
    
    

with all_values as (

    select
        benchmark_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics
    group by benchmark_status

)

select *
from all_values
where value_field not in (
    'ABOVE_BENCHMARK','NEAR_BENCHMARK','BELOW_BENCHMARK'
)


