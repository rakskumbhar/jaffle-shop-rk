
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified
where npi_number is not null
group by npi_number
having count(*) > 1


