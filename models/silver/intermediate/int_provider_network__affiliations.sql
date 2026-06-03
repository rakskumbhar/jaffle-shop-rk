{{ config(
    materialized='incremental',
    unique_key='affiliation_sk',
    incremental_strategy='merge',
    cluster_by=['npi_number']
) }}

with source as (
    select * from {{ ref('stg_network__affiliations') }}
    {% if is_incremental() %}
        where _source_loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),

enriched as (
    select
        {{ generate_surrogate_key(['network_affiliation_id']) }} as affiliation_sk,
        s.*,
        case
            when s.participation_status = 'PARTICIPATING'
                 and (s.termination_date is null or s.termination_date > current_date())
            then true
            else false
        end as is_currently_participating,
        current_timestamp() as _enriched_at
    from source s
)

select * from enriched
