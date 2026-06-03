
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.GOLD.provider_360_summary
where npi_number is not null
group by npi_number
having count(*) > 1


