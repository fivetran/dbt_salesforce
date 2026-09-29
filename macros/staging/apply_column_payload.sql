{% macro apply_column_payload(staging_columns, column_payload) %}
{#
    Replaces the old `fill_staging_columns` (fed by `adapter.get_columns_in_relation`) +
    `coalesce_rename` combination. `staging_columns` is a `get_*_columns()` list
    ({name, datatype, alias?}); `column_payload` is a normalized dict of
    canonical_name -> current_name for every column the connector currently produces.

    Since the payload is exhaustive, presence/absence and the exact current spelling are
    both already known -- no coalescing between guessed spellings and no
    adapter.get_columns_in_relation call is needed.
#}
{%- for column in staging_columns -%}
    {%- set current_name = column_payload.get(column.name | lower) -%}
    {%- set output_name = column.alias if 'alias' in column else column.name -%}
    {%- if current_name is not none %}
        cast({{ fivetran_utils.quote_column({"name": current_name}) }} as {{ column.datatype }}) as {{ fivetran_utils.quote_column({"name": output_name}) }}
    {%- else %}
        cast(null as {{ column.datatype }}) as {{ fivetran_utils.quote_column({"name": output_name}) }}
    {%- endif %}{{ ',' if not loop.last }}
{%- endfor -%}
{% endmacro %}
