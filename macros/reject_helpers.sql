{% macro get_reject_reasons(column_checks) %}
{%- for check in column_checks -%}
    case when {{ check.condition }} then '{{ check.reason }}' end
    {%- if not loop.last %}, {% endif -%}
{%- endfor -%}
{% endmacro %}

{% macro build_reject_reason_array(column_checks) %}
array_compact(array_construct(
    {%- for check in column_checks %}
    case when {{ check.condition }} then '{{ check.reason }}' end
    {%- if not loop.last %},{% endif -%}
    {%- endfor %}
))
{% endmacro %}
