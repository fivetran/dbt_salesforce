{% macro get_source_identifier(schema_name, table_name, default=table_name) %}
{#
    Resolves a table's physical identifier from the same exhaustive salesforce__column_payload
    var select_payload_fields uses, instead of a per-table `salesforce_<table>_identifier` var.
    Used directly in a source yml's `identifier:` config, with schema_name passed in explicitly
    (e.g. var('salesforce_schema', 'salesforce')) since this runs before source() itself can
    resolve it. Falls back to `default` (the standard table name, or a caller-supplied literal
    for reserved-word cases like Snowflake's "order") when the payload has no entry.
#}
{%- set schema_payload = (var('salesforce__column_payload', {}) or {}).get(schema_name | lower, {}) -%}
{%- set table_payload = schema_payload.get(table_name | lower, {}) -%}
{{ return(table_payload.get('__identifier__', default)) }}
{% endmacro %}
