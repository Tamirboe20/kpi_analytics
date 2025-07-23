{% macro churn_cutoff(order_date) %}
    {{ order_date }} < date_add({{ var('run_date') }}, interval -{{ var('churn_threshold_months') }} month)
{% endmacro %}
