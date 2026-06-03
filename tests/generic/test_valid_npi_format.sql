{% test valid_npi_format(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and (
    length({{ column_name }}) != 10
    or try_to_number({{ column_name }}) is null
  )

{% endtest %}
