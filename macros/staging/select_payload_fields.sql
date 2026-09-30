{% macro select_payload_fields(source_name, table_name, staging_columns, payload_key=none) %}
{#
    Everything a `fields` CTE needs, in one call: resolves source(source_name, table_name),
    rebuilds the relation with the payload's __identifier__ (via get_source_identifier),
    drills the exhaustive salesforce__column_payload var down to this table
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

    The identifier override happens here, in a normal macro context, not in the source yml's
    `identifier:` config -- real dbt-core cannot render custom macros (even self-namespaced
    ones) inside a source config's Jinja, only built-in globals like var()/env_var()/target.
    Confirmed directly against real dbt-core 1.11 (both interactively and via this package's
    own Buildkite CI, which failed identically across postgres/snowflake/duckdb with
    "'salesforce' is undefined" the one time this was tried from the yml). So
    source(source_name, table_name)'s own `identifier:` stays a plain var()-based default (as
    it always was), and this macro builds an *overriding* relation from the payload's
    __identifier__ on top of it via api.Relation.create(), falling back to that plain
    var()-based identifier (not a bare literal) when the payload has no entry for this table.

    source(source_name, table_name) is still the tie back to the source yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work, using
    whatever plain var()-based identifier is configured there. This macro's FROM clause reads
    from the payload-driven override instead, which usually matches but isn't required to.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('salesforce', 'campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set payload_key = payload_key or table_name -%}
{%- set table_source = source(source_name, table_name) -%}
{%- set identifier = salesforce.get_source_identifier(table_source.schema, payload_key, default=table_source.identifier) -%}
{%- set table_relation = api.Relation.create(database=table_source.database, schema=table_source.schema, identifier=identifier) -%}
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

    from {{ table_relation }}

{%- endmacro %}
