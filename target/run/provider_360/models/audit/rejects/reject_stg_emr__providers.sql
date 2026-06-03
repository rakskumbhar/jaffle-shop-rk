begin;
    insert into SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_emr__providers ("REJECT_ID", "SOURCE_MODEL", "NPI_NUMBER", "REJECT_REASONS", "_SOURCE_LOADED_AT", "DBT_INVOCATION_ID", "REJECTED_AT")
    (
        select "REJECT_ID", "SOURCE_MODEL", "NPI_NUMBER", "REJECT_REASONS", "_SOURCE_LOADED_AT", "DBT_INVOCATION_ID", "REJECTED_AT"
        from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_emr__providers__dbt_tmp
    )

;
    commit;