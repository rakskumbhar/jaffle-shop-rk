

select
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as run_id,
    'dev' as target_environment,
    'DBT_RKUMBHAR' as target_schema,
    'SNOWFLAKE_LEARNING_DB' as target_database,
    '2026-06-02 18:28:33.317680+00:00' as run_started_at,
    current_timestamp() as run_completed_at,
    timestampdiff('second', '2026-06-02 18:28:33.317680+00:00'::timestamp_ntz, current_timestamp()) as run_duration_seconds,
    '2026-06-02 11:28:37' as dbt_invocation_time,
    current_timestamp() as _loaded_at