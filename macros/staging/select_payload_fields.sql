{% macro select_payload_fields(table_name, staging_columns) %}
{#
    Consolidates everything a `fields` CTE needs into one call: resolves
    source('salesforce', table_name), drills the exhaustive payload down to this table via
    normalize_column_payload, and emits the full `select ... from ...` body using
    apply_column_payload for the column list.

    source('salesforce', table_name) is the only tie back to src_salesforce.yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work. Its
    `identifier:` config is itself payload-driven (via get_source_identifier, used directly
    in src_salesforce.yml), so source(...) already resolves to the payload's __identifier__
    when one exists, with the same table_name fallback otherwise -- no separate override
    needed here.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set table_source = source('salesforce', table_name) -%}
{%- set column_payload = normalize_column_payload(var('salesforce__column_payload', {}), table_source.schema, table_name) -%}

    select
        {{ apply_column_payload(staging_columns, column_payload) }}

    from {{ table_source }}

{%- endmacro %}
