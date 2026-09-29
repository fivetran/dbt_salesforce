{% macro get_source_identifier(table_name, default=table_name) %}
{#
    Resolves a table's physical identifier from the same exhaustive payload
    apply_column_payload uses, instead of a per-table `salesforce_<table>_identifier` var.
    Used directly in src_salesforce.yml's `identifier:` config, so source('salesforce', ...)
    itself reflects the payload's __identifier__ -- no separate override needed later. Falls
    back to `default` (the standard table name, or a caller-supplied literal for reserved-word
    cases like Snowflake's "order") when the payload has no entry for this table.
#}
{%- set schema_name = var('salesforce_schema', 'salesforce') -%}
{%- set column_payload = normalize_column_payload(var('salesforce__column_payload', {}), schema_name, table_name) -%}
{{ return(column_payload.get('__identifier__', default)) }}
{% endmacro %}
