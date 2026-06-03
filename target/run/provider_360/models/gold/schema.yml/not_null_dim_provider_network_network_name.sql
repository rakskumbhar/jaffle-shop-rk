select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select network_name
from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network
where network_name is null



      
    ) dbt_internal_test