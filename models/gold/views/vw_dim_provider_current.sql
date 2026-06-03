{{ config(
    materialized='view',
    tags=['gold', 'provider', 'dim', 'consumer_view']
) }}

select * from {{ ref('dim_provider') }}
where is_current = true
