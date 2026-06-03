




select
    md5(coalesce(cast('reject_stg_npi__registry' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as summary_id,
    'reject_stg_npi__registry' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as summarized_at
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_npi__registry,
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = 'ce3674b4-796d-475b-9f6e-d44a5edfe7cb'
group by 1, 2, 3
union all

select
    md5(coalesce(cast('reject_stg_cred__providers' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as summary_id,
    'reject_stg_cred__providers' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as summarized_at
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_cred__providers,
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = 'ce3674b4-796d-475b-9f6e-d44a5edfe7cb'
group by 1, 2, 3
union all

select
    md5(coalesce(cast('reject_stg_emr__providers' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as summary_id,
    'reject_stg_emr__providers' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as summarized_at
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_emr__providers,
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = 'ce3674b4-796d-475b-9f6e-d44a5edfe7cb'
group by 1, 2, 3
union all

select
    md5(coalesce(cast('reject_stg_claims__providers' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as summary_id,
    'reject_stg_claims__providers' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as summarized_at
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_claims__providers,
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = 'ce3674b4-796d-475b-9f6e-d44a5edfe7cb'
group by 1, 2, 3
union all

select
    md5(coalesce(cast('reject_stg_network__affiliations' as varchar), '_dbt_utils_surrogate_key_null_') || '|' || coalesce(cast('ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as varchar), '_dbt_utils_surrogate_key_null_')) as summary_id,
    'reject_stg_network__affiliations' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    'ce3674b4-796d-475b-9f6e-d44a5edfe7cb' as dbt_invocation_id,
    current_timestamp() as summarized_at
from SNOWFLAKE_LEARNING_DB.REJECT.reject_stg_network__affiliations,
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = 'ce3674b4-796d-475b-9f6e-d44a5edfe7cb'
group by 1, 2, 3

