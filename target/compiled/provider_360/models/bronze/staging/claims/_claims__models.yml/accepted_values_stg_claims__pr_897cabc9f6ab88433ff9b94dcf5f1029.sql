
    
    

with all_values as (

    select
        claim_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
    group by claim_status

)

select *
from all_values
where value_field not in (
    'PAID','DENIED','PENDING','ADJUSTED'
)


