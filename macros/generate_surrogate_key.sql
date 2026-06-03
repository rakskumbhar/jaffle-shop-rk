{% macro generate_surrogate_key(field_list) %}
    {%- set fields = [] -%}
    {%- for field in field_list -%}
        {%- do fields.append("coalesce(cast(" ~ field ~ " as varchar), '_dbt_utils_surrogate_key_null_')") -%}
    {%- endfor -%}
    md5({{ fields | join(" || '|' || ") }})
{%- endmacro %}
