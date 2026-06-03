
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from SNOWFLAKE_LEARNING_DB.RAW.stg_npi__registry
where npi_number is not null
group by npi_number
having count(*) > 1


