{% macro apply_column_payload(staging_columns, column_payload) %}
{#
    Payload-driven replacement for fivetran_utils.fill_staging_columns +
    adapter.get_columns_in_relation: `column_payload` is the normalized, exhaustive
    canonical_name -> current_name map for this table, so presence/absence and the exact
    current spelling are already known -- no introspection needed. Mirrors
    fill_staging_columns' own branching (and its `alias` support) exactly, just swapping the
    introspected source-columns membership check for a payload lookup.
#}
{%- for column in staging_columns %}
    {%- set current_name = column_payload.get(column.name | lower) %}
    {%- if current_name is not none %}
        {{ fivetran_utils.quote_column({"name": current_name}) }} as
        {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
    {%- else %}
        cast(null as {{ column.datatype }}) as
        {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
    {%- endif %}{{ ',' if not loop.last }}
{%- endfor %}
{%- endmacro %}
