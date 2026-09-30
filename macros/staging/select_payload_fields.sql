{% macro select_payload_fields(source_name, table_name, staging_columns) %}
{#
    Everything a `fields` CTE needs, in one call: resolves source(source_name, table_name),
    drills the exhaustive salesforce__column_payload var down to this table
    (payload[schema][table_name], case-insensitive), and emits the full `select ... from ...`
    body -- present columns pass through raw/uncast under their current name, absent columns
    get `cast(null as datatype)`, mirroring fivetran_utils.fill_staging_columns' own branching
    (and its `alias` support) but driven by the payload instead of
    adapter.get_columns_in_relation, so no introspection is needed.

    source(source_name, table_name) is the only tie back to the source yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work. Its
    `identifier:` config is itself payload-driven (via get_source_identifier, used directly
    in the source yml), so source(...) already resolves to the payload's __identifier__ when
    one exists, with the same table_name fallback otherwise -- no separate override needed
    here.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('salesforce', 'campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set table_source = source(source_name, table_name) -%}
{%- set schema_payload = (var('salesforce__column_payload', {}) or {}).get(table_source.schema | lower, {}) -%}
{%- set column_payload = {} -%}
{%- for original_name, current_name in (schema_payload.get(table_name | lower, {}) or {}).items() -%}
    {%- do column_payload.update({original_name | lower: current_name}) -%}
{%- endfor -%}

    select
        {%- for column in staging_columns %}
        {%- set current_name = column_payload.get(column.name | lower) %}
        {%- if current_name is not none %}
            {{ fivetran_utils.quote_column({"name": current_name}) }} as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- else %}
            cast(null as {{ column.datatype }}) as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- endif %}{{ ',' if not loop.last }}
        {%- endfor %}

    from {{ table_source }}

{%- endmacro %}
