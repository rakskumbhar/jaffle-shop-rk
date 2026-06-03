select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        is_accepting_patients as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
    group by is_accepting_patients

)

select *
from all_values
where value_field not in (
    'True','False'
)



      
    ) dbt_internal_test