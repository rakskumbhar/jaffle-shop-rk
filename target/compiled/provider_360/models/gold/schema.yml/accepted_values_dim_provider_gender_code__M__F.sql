
    
    

with all_values as (

    select
        gender_code as value_field,
        count(*) as n_records

    from (select * from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider where entity_type_code = '1') dbt_subquery
    group by gender_code

)

select *
from all_values
where value_field not in (
    'M','F'
)


