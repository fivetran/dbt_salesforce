{% macro get_source_identifier(payload_key, default=payload_key) %}
{#
    Resolves a table's physical identifier from the same exhaustive salesforce__column_payload
    var select_payload_fields uses, instead of a per-table `salesforce_<table>_identifier` var.
    Used directly in a source yml's `identifier:` config. Falls back to `default` (the standard
    table name, or a caller-supplied literal for reserved-word cases like Snowflake's "order")
    when the payload has no entry.

    payload_key must match whatever select_payload_fields uses for this same table (see its
    own payload_key doc) -- pass an explicit `default` alongside it whenever payload_key isn't
    also the table's real physical name (e.g. history tables use 'account_history' as the
    payload_key to avoid colliding with the core `account` table's own entry, but still want
    'account' as the literal fallback).

    The payload is flat (payload[table]), not schema-keyed -- see select_payload_fields for why.
#}
{%- set table_payload = (var('salesforce__column_payload', {}) or {}).get(payload_key | lower, {}) -%}
{{ return(table_payload.get('__identifier__', default)) }}
{% endmacro %}
