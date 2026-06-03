{{ config(
    materialized='incremental',
    unique_key='row_count_id',
    incremental_strategy='append',
    schema='AUDIT',
    tags=['audit']
) }}

{% set source_tables = [
    {"source_name": "npi_registry", "table_name": "npi_raw"},
    {"source_name": "credentialing", "table_name": "provider_credentials_raw"},
    {"source_name": "emr", "table_name": "provider_master_raw"},
    {"source_name": "claims", "table_name": "claims_raw"},
    {"source_name": "network", "table_name": "network_affiliations_raw"}
] %}

{% for src in source_tables %}
select
    {{ generate_surrogate_key(["'" ~ src.source_name ~ "." ~ src.table_name ~ "'", "'" ~ invocation_id ~ "'"]) }} as row_count_id,
    '{{ src.source_name }}' as source_name,
    '{{ src.table_name }}' as table_name,
    count(*) as row_count,
    min(_loaded_at) as earliest_loaded_at,
    max(_loaded_at) as latest_loaded_at,
    '{{ invocation_id }}' as dbt_invocation_id,
    current_timestamp() as measured_at
from {{ source(src.source_name, src.table_name) }}
group by 1, 2, 3
{% if not loop.last %}union all{% endif %}
{% endfor %}
