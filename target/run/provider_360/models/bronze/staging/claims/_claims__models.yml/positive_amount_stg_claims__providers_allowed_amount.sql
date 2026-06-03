select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      

select allowed_amount
from SNOWFLAKE_LEARNING_DB.RAW.stg_claims__providers
where allowed_amount < 0


      
    ) dbt_internal_test