select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    provider_network_sk as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.GOLD.dim_provider_network
where provider_network_sk is not null
group by provider_network_sk
having count(*) > 1



      
    ) dbt_internal_test