{% macro get_history_columns(base_columns, id_alias) %}
{#
    Reuses the core staging table's own get_*_columns() list for a history model instead of
    a near-duplicate get_*_history_columns() macro -- the history source is the same
    connector object, just with _fivetran_start/_fivetran_end added and `id` aliased to the
    table's day-grain id column (e.g. account_id) instead of whatever the core staging model
    aliases it to.
#}
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
