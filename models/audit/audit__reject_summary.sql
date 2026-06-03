{{ config(
    materialized='incremental',
    unique_key='summary_id',
    incremental_strategy='append',
    schema='AUDIT',
    tags=['audit']
) }}

{% set reject_models = [
    'reject_stg_npi__registry',
    'reject_stg_cred__providers',
    'reject_stg_emr__providers',
    'reject_stg_claims__providers',
    'reject_stg_network__affiliations'
] %}

{% for reject_model in reject_models %}
select
    {{ generate_surrogate_key(["'" ~ reject_model ~ "'", "'" ~ invocation_id ~ "'"]) }} as summary_id,
    '{{ reject_model }}' as reject_model,
    reject_reasons.value::varchar as reject_reason,
    count(*) as reject_count,
    min(rejected_at) as first_rejected_at,
    max(rejected_at) as last_rejected_at,
    '{{ invocation_id }}' as dbt_invocation_id,
    current_timestamp() as summarized_at
from {{ ref(reject_model) }},
    lateral flatten(input => reject_reasons) as reject_reasons
where dbt_invocation_id = '{{ invocation_id }}'
group by 1, 2, 3
{% if not loop.last %}union all{% endif %}
{% endfor %}
