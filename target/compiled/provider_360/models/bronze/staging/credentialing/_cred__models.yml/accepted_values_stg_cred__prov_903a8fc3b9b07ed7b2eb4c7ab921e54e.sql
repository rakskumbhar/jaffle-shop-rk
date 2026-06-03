
    
    

with all_values as (

    select
        credential_status as value_field,
        count(*) as n_records

    from SNOWFLAKE_LEARNING_DB.RAW.stg_cred__providers
    group by credential_status

)

select *
from all_values
where value_field not in (
    'ACTIVE','EXPIRED','PENDING','REVOKED'
)


