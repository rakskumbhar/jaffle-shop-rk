
  
    

        create or replace transient table SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics
         as
        (select * from (
              

with source as (
    select
        quality_metric_id::varchar        as quality_metric_id,
        npi_number::varchar(10)           as npi_number,
        measure_name::varchar             as measure_name,
        measure_category::varchar         as measure_category,
        score::number(5,1)                as score,
        benchmark_score::number(5,1)      as benchmark_score,
        measurement_period_start::date    as measurement_period_start,
        measurement_period_end::date      as measurement_period_end,
        sample_size::integer              as sample_size,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from SNOWFLAKE_LEARNING_DB.SEEDS.quality_metrics_raw
    
),

enriched as (
    select
        md5(coalesce(cast(quality_metric_id as varchar), '_dbt_utils_surrogate_key_null_')) as quality_metric_sk,
        s.*,
        case
            when s.score >= s.benchmark_score then 'ABOVE_BENCHMARK'
            when s.score >= s.benchmark_score * 0.9 then 'NEAR_BENCHMARK'
            else 'BELOW_BENCHMARK'
        end as benchmark_status,
        s.score - s.benchmark_score as score_variance,
        current_timestamp() as _enriched_at
    from source s
)

select * from enriched
              ) order by (npi_number)
        );
      alter  table SNOWFLAKE_LEARNING_DB.SILVER.int_provider_quality__metrics cluster by (npi_number);
  