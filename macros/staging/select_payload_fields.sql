{% macro select_payload_fields(table_name, staging_columns) %}
{#
    Consolidates everything a `fields` CTE needs into one call: resolves
    source('salesforce', table_name) for schema/database, drills the exhaustive payload
    down to this table via normalize_column_payload, rebuilds the relation from the
    payload's __identifier__, and emits the full `select ... from ...` body using
    apply_column_payload for the column list.

    source('salesforce', table_name) is still the tie back to src_salesforce.yml: it's
    what makes docs, lineage, and `dbt source freshness` work, and its own `identifier:`
    (the `salesforce__<table>_identifier` var) is the only thing dbt's own tooling can see.
    The payload's __identifier__ is treated as an override on top of that -- when a table
    is missing from the payload, or its dict has no __identifier__, this falls back to
    table_source.identifier (the yml-configured one), not a bare literal table_name, so an
    incomplete payload can't silently point the query at the wrong physical table.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set table_source = source('salesforce', table_name) -%}
{%- set column_payload = normalize_column_payload(var('salesforce__column_payload', {}), table_source.schema, table_name) -%}
{%- set table_relation = api.Relation.create(
    database=table_source.database,
    schema=table_source.schema,
    identifier=column_payload.get('__identifier__', table_source.identifier)
) -%}

    select
        {{ apply_column_payload(staging_columns, column_payload) }}

    from {{ table_relation }}

{%- endmacro %}
