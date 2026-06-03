

select npi_number
from SNOWFLAKE_LEARNING_DB.GOLD.fct_quality_metrics
where npi_number is not null
  and (
    length(npi_number) != 10
    or try_to_number(npi_number) is null
  )

