{{ config(
    materialized='incremental',
    unique_key='provider_dedup_key',
    incremental_strategy='merge',
    cluster_by=['npi_number', 'source_system']
) }}

with unified as (
    select * from {{ ref('int_providers__unified') }}
    {% if is_incremental() %}
        where _unified_at > (select max(_unified_at) from {{ this }})
    {% endif %}
),

deduped as (
    select
        {{ generate_surrogate_key(['npi_number']) }} as provider_dedup_key,
        *,
        row_number() over (
            partition by npi_number
            order by _source_loaded_at desc
        ) as _dedup_rank,
        'NPI_REGISTRY' as source_system
    from unified
)

select * from deduped
where _dedup_rank = 1
