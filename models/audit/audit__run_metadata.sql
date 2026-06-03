{{ config(
    materialized='incremental',
    unique_key='run_id',
    incremental_strategy='append',
    schema='AUDIT',
    tags=['audit']
) }}

select
    '{{ invocation_id }}' as run_id,
    '{{ target.name }}' as target_environment,
    '{{ target.schema }}' as target_schema,
    '{{ target.database }}' as target_database,
    '{{ run_started_at }}' as run_started_at,
    current_timestamp() as run_completed_at,
    timestampdiff('second', '{{ run_started_at }}'::timestamp_ntz, current_timestamp()) as run_duration_seconds,
    '{{ modules.datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") }}' as dbt_invocation_time,
    current_timestamp() as _loaded_at
