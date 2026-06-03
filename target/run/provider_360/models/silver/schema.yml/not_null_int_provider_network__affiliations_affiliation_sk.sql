select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select affiliation_sk
from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations
where affiliation_sk is null



      
    ) dbt_internal_test