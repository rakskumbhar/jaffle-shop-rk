
    
    

with all_values as (

    select
        participation_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network
    group by participation_status

)

select *
from all_values
where value_field not in (
    'PARTICIPATING','TERMINATED','SUSPENDED'
)


