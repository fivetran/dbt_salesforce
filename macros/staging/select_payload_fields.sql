{% macro select_payload_fields(source_name, table_name, staging_columns, payload_key=none) %}
{#
    Everything a `fields` CTE needs, in one call: resolves source(source_name, table_name) --
    whose `identifier:` is itself payload-driven, via get_source_identifier called directly in
    the source yml -- drills the exhaustive salesforce__column_payload var down to this table
    (payload[schema][payload_key], case-insensitive), and emits the full `select ... from ...`
    body -- present columns pass through, quoted, under their current name; absent columns
    get `cast(null as datatype)`. Mirrors fivetran_utils.fill_staging_columns' own branching
    (and its `alias` support) but driven by the payload instead of
    adapter.get_columns_in_relation, so no introspection is needed.

    A present column's current name is always quoted (quote_column with quote=true), not
    passed through bare: the payload can supply any spelling a connector actually produced
    (e.g. raw camelCase like `AccountNumber`), and most warehouses fold an *unquoted*
    identifier to their own default case (Postgres/Redshift to lowercase, Snowflake to
    uppercase) rather than preserving whatever case dbt seed/the connector actually created the
    column with. Confirmed directly: real dbt-core against real Postgres failed with `column
    "accountnumber" does not exist` (the physical column was `AccountNumber`, case-preserved)
    until this was quoted. Quoting a plain lowercase/underscore name this same way is a no-op
    on every warehouse, so there's no cost for the common (unrenamed) case.

    payload_key defaults to table_name -- pass it explicitly only when two different sources'
    tables would otherwise share the same key (e.g. the salesforce_history source's `account`
    table vs. the core `salesforce` source's own `account` table): pass a distinct key like
    'account_history' so the two don't collide in the payload dict.

    This package is v2 (dbt-oss/Fusion) only going forward: get_source_identifier is called
    directly from the source yml's `identifier:` config, which real dbt-core cannot render
    (confirmed via this package's own Buildkite CI -- build #273 failed identically across
    postgres/snowflake/duckdb with "'salesforce' is undefined" the one time this was tried).
    An earlier revision moved that call into this macro instead, building an overriding
    relation via api.Relation.create() so real dbt-core would keep working too -- reverted
    deliberately, since the goal is the v2-only yml-based design, not v1 compatibility.

    source(source_name, table_name) is the only tie back to the source yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work, and its
    `identifier:` already resolves to the payload's __identifier__ (falling back to the
    standard table name) via get_source_identifier. This macro's FROM clause just reads from
    it directly -- no separate override needed.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('salesforce', 'campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set payload_key = payload_key or table_name -%}
{%- set table_source = source(source_name, table_name) -%}
{%- set full_payload = var('salesforce__column_payload', {}) or {} -%}
{%- if full_payload | length == 1 -%}
    {%- set schema_payload = full_payload.values() | first -%}
{%- else -%}
    {%- set schema_payload = full_payload.get(table_source.schema | lower, {}) -%}
{%- endif -%}
{%- set column_payload = {} -%}
{%- for original_name, current_name in ((schema_payload or {}).get(payload_key | lower, {}) or {}).items() -%}
    {%- do column_payload.update({original_name | lower: current_name}) -%}
{%- endfor -%}

    select
        {%- for column in staging_columns %}
        {%- set current_name = column_payload.get(column.name | lower) %}
        {%- if current_name is not none %}
            {{ fivetran_utils.quote_column({"name": current_name, "quote": true}) }} as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- else %}
            cast(null as {{ column.datatype }}) as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- endif %}{{ ',' if not loop.last }}
        {%- endfor %}

    from {{ table_source }}

{%- endmacro %}
