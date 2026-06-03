
    
    

with child as (
    select npi_number as from_field
    from SNOWFLAKE_LEARNING_DB.SILVER.int_provider_network__affiliations
    where npi_number is not null
),

parent as (
    select npi_number as to_field
    from SNOWFLAKE_LEARNING_DB.SILVER.int_providers__unified
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


