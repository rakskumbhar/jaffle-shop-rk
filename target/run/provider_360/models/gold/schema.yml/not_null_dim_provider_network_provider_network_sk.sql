select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select provider_network_sk
from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network
where provider_network_sk is null



      
    ) dbt_internal_test