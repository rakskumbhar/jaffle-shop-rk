
    
    

with all_values as (

    select
        npi_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
    group by npi_status

)

select *
from all_values
where value_field not in (
    'A','D','R'
)


