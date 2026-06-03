select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select address_line_1
from SNOWFLAKE_LEARNING_DB.RAW.stg_emr__providers
where address_line_1 is null



      
    ) dbt_internal_test