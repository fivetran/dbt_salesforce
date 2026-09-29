{% macro select_payload_fields(table_name, staging_columns) %}
{#
    Consolidates everything a `fields` CTE needs into one call: resolves
    source('salesforce', table_name) for schema/database, drills the exhaustive payload
    down to this table via normalize_column_payload, rebuilds the relation from the
    payload's __identifier__ (falling back to table_name itself when absent), and emits
    the full `select ... from ...` body using apply_column_payload for the column list.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('campaign_member', campaign_member_column_list) }}
        ),
#}
{%- set table_source = source('salesforce', table_name) -%}
{%- set column_payload = normalize_column_payload(var('salesforce__column_payload', {}), table_source.schema, table_name) -%}
{%- set table_relation = api.Relation.create(
    database=table_source.database,
    schema=table_source.schema,
    identifier=column_payload.get('__identifier__', table_name)
) -%}

    select
        {{ apply_column_payload(staging_columns, column_payload) }}

    from {{ table_relation }}

{%- endmacro %}
