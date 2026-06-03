{% test row_count_above_zero(model) %}

select 1
where (select count(*) from {{ model }}) = 0

{% endtest %}
