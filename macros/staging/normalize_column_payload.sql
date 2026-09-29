{% macro normalize_column_payload(full_payload, schema_name, table_name) %}
{#
    The quickstart runtime supplies a single exhaustive payload for the whole package,
    keyed by schema then table, covering every column each table's connector produces
    (renamed or not): {schema: {table: {canonical_column_name: current_column_name}}}.

    This drills down to the flat canonical_name -> current_name dict for one table and
    lowercases its keys so `apply_column_payload` can look columns up case-insensitively.
    A table missing from the payload behaves like an empty payload: every column for that
    table is treated as absent and null-filled.
#}
{%- set schema_payload = (full_payload or {}).get(schema_name | lower, {}) -%}
{%- set table_payload = (schema_payload or {}).get(table_name | lower, {}) -%}
{%- set normalized_payload = {} -%}
{%- for original_name, current_name in (table_payload or {}).items() -%}
    {%- do normalized_payload.update({original_name | lower: current_name}) -%}
{%- endfor -%}
{{ return(normalized_payload) }}
{% endmacro %}
