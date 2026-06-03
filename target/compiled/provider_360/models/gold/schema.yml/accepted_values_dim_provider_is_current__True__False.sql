
    
    

with all_values as (

    select
        is_current as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
    group by is_current

)

select *
from all_values
where value_field not in (
    'True','False'
)


