{% macro log_run_start() %}
    {% if execute %}
        {{ log("dbt run started at " ~ run_started_at ~ " | invocation_id: " ~ invocation_id, info=true) }}
    {% endif %}
{% endmacro %}

{% macro log_run_end() %}
    {% if execute %}
        {{ log("dbt run completed | invocation_id: " ~ invocation_id, info=true) }}
    {% endif %}
{% endmacro %}
