

with quality as (
    select * from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics
),

facts as (
    select
        quality_metric_sk,
        quality_metric_id,
        npi_number,
        measure_name,
        measure_category,
        score,
        benchmark_score,
        score_variance,
        benchmark_status,
        measurement_period_start,
        measurement_period_end,
        sample_size,
        case
            when score >= 90 then 'EXCELLENT'
            when score >= 75 then 'GOOD'
            when score >= 60 then 'FAIR'
            else 'NEEDS_IMPROVEMENT'
        end as performance_tier,
        _source_loaded_at,
        current_timestamp() as _dbt_loaded_at
    from quality
)

select * from facts