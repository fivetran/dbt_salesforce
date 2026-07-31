{% macro history_spine_start_date(first_date) %}

{%- if is_incremental() -%}
{{ salesforce.salesforce_lookback(
    from_date='max(date_day)',
    datepart='day',
    interval=var('lookback_window', 1),
    safety_date=first_date[0:10]
    ) }}
{%- else -%}
cast('{{ first_date[0:10] }}' as date)
{%- endif -%}

{% endmacro %}
