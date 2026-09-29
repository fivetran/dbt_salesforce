{% macro normalize_column_payload(full_payload, schema_name, table_name) %}
{#
    The quickstart runtime supplies a single exhaustive payload for the whole package,
    keyed by schema then by the package's standard table name (the same literal name
    passed to source(), e.g. 'account' -- not the customer's actual physical identifier):
    {schema: {standard_table_name: {canonical_column_name: current_column_name}}}.

    Each table's dict also carries a `__identifier__` entry giving the actual physical
    table name for that customer, so the model can build its FROM relation from the
    payload instead of a per-table identifier var. `__identifier__` passes through this
    macro like any other key -- callers pull it out of the returned dict themselves.

    This drills down to the flat dict for one table and lowercases its keys so
    `apply_column_payload` can look columns up case-insensitively. A table missing from
    the payload behaves like an empty payload: every column for that table is treated as
    absent and null-filled, and `__identifier__` falls back to the standard table name.
#}
{%- set schema_payload = (full_payload or {}).get(schema_name | lower, {}) -%}
{%- set table_payload = (schema_payload or {}).get(table_name | lower, {}) -%}
{%- set normalized_payload = {} -%}
{%- for original_name, current_name in (table_payload or {}).items() -%}
    {%- do normalized_payload.update({original_name | lower: current_name}) -%}
{%- endfor -%}
{{ return(normalized_payload) }}
{% endmacro %}
