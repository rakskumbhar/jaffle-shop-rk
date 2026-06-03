select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        is_fully_active as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider
    group by is_fully_active

)

select *
from all_values
where value_field not in (
    'True','False'
)



      
    ) dbt_internal_test