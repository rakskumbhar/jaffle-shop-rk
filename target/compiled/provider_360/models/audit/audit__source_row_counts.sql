




select
    md5(coalesce(cast('npi_registry.npi_raw' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as row_count_id,
    'npi_registry' as source_name,
    'npi_raw' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as measured_at
from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.npi_raw
group by 1, 2, 3
union all

select
    md5(coalesce(cast('credentialing.provider_credentials_raw' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as row_count_id,
    'credentialing' as source_name,
    'provider_credentials_raw' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as measured_at
from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_credentials_raw
group by 1, 2, 3
union all

select
    md5(coalesce(cast('emr.provider_master_raw' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as row_count_id,
    'emr' as source_name,
    'provider_master_raw' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as measured_at
from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.provider_master_raw
group by 1, 2, 3
union all

select
    md5(coalesce(cast('claims.claims_raw' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as row_count_id,
    'claims' as source_name,
    'claims_raw' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as measured_at
from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.claims_raw
group by 1, 2, 3
union all

select
    md5(coalesce(cast('network.network_affiliations_raw' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as row_count_id,
    'network' as source_name,
    'network_affiliations_raw' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as measured_at
from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.network_affiliations_raw
group by 1, 2, 3

