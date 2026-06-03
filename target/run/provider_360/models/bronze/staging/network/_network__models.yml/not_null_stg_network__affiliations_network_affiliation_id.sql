select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select network_affiliation_id
from SNOWFLAKE_LEARNING_DB.RAW.stg_network__affiliations
where network_affiliation_id is null



      
    ) dbt_internal_test