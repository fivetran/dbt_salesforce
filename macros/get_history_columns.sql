{% macro get_history_columns(base_columns, id_alias) %}
{# Core table's columns plus _fivetran_start/_fivetran_end, with `id` aliased to id_alias #}
{%- set history_columns = base_columns + [
    {"name": "_fivetran_start", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_end", "datatype": dbt.type_timestamp()}
] -%}
{%- for column in history_columns -%}
    {%- if column.name == "id" -%}
        {%- do column.update({"alias": id_alias}) -%}
    {%- endif -%}
{%- endfor -%}
{{ return(history_columns) }}
{% endmacro %}
