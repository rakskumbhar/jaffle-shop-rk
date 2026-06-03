begin;
    insert into SNOWFLAKE_LEARNING_DB.AUDIT.audit__source_row_counts ("ROW_COUNT_ID", "SOURCE_NAME", "TABLE_NAME", "ROW_COUNT", "EARLIEST_LOADED_AT", "LATEST_LOADED_AT", "DBT_INVOCATION_ID", "MEASURED_AT")
    (
        select "ROW_COUNT_ID", "SOURCE_NAME", "TABLE_NAME", "ROW_COUNT", "EARLIEST_LOADED_AT", "LATEST_LOADED_AT", "DBT_INVOCATION_ID", "MEASURED_AT"
        from SNOWFLAKE_LEARNING_DB.AUDIT.audit__source_row_counts__dbt_tmp
    )

;
    commit;