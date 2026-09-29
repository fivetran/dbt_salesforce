{% macro normalize_column_payload(raw_payload) %}
{#
    Normalizes the exhaustive column payload the quickstart runtime supplies for a table
    (a dict of canonical_column_name -> current_column_name in the source table, covering
    every column the connector produces, renamed or not) before it's consumed column-by-column
    by `apply_column_payload`. Keys are lowercased so lookups are case-insensitive; values are
    left untouched since a renamed column's actual spelling can be meaningfully cased.

    A canonical column absent from the payload means the column doesn't exist for this
    customer -- `apply_column_payload` null-fills it using the datatype from the matching
    `get_*_columns()` macro. There is no introspection fallback: an unset/empty payload means
    every column is treated as absent.
#}
{%- set normalized_payload = {} -%}
{%- for original_name, current_name in (raw_payload or {}).items() -%}
    {%- do normalized_payload.update({original_name | lower: current_name}) -%}
{%- endfor -%}
{{ return(normalized_payload) }}
{% endmacro %}
