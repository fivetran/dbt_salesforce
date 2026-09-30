{% macro select_payload_fields(source_name, table_name, staging_columns, payload_key=none) %}
{#
    Everything a `fields` CTE needs, in one call: resolves source(source_name, table_name),
    drills the exhaustive salesforce__column_payload var down to this table
    (payload[payload_key], case-insensitive), and emits the full `select ... from ...` body --
    present columns pass through raw/uncast under their current name, absent columns get
    `cast(null as datatype)`, mirroring fivetran_utils.fill_staging_columns' own branching (and
    its `alias` support) but driven by the payload instead of adapter.get_columns_in_relation,
    so no introspection is needed.

    payload_key defaults to table_name -- pass it explicitly only when two different sources'
    tables would otherwise share the same key (e.g. the salesforce_history source's `account`
    table vs. the core `salesforce` source's own `account` table): pass a distinct key like
    'account_history' so the two don't collide in the payload dict.

    The payload is flat (payload[table]), not schema-keyed: Salesforce doesn't union across
    multiple source schemas/orgs in staging, so a schema level here was pure overhead -- worse,
    it was a real, recurring source of failures whenever a schema var (salesforce_schema /
    salesforce_history_schema) was pointed at a different environment (e.g. switching from
    DuckDB to BigQuery) without also updating the payload's top-level key to match. A package
    that *does* union across schemas/orgs should reintroduce a schema (or source_relation) level
    here when porting this pattern -- this macro's shape (resolve source, drill the payload by
    a single key, apply_column_payload-style column loop) is the reusable part.

    source(source_name, table_name) is the only tie back to the source yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work. Its
    `identifier:` config is itself payload-driven (via get_source_identifier, used directly
    in the source yml with the same payload_key), so source(...) already resolves to the
    payload's __identifier__ when one exists, with the standard table name as fallback
    otherwise -- no separate override needed here.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('salesforce', 'campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set payload_key = payload_key or table_name -%}
{%- set table_source = source(source_name, table_name) -%}
{%- set column_payload = {} -%}
{%- for original_name, current_name in ((var('salesforce__column_payload', {}) or {}).get(payload_key | lower, {}) or {}).items() -%}
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
