{% macro select_payload_fields(source_name, table_name, staging_columns, payload_key=none) %}
{#
    Everything a `fields` CTE needs, in one call: resolves source(source_name, table_name) --
    whose `identifier:` config is the original, unmodified main logic (plain
    var('salesforce_<table>_identifier', '<table>')), untouched by this work -- drills the
    exhaustive salesforce__source_config var down to this table's `columns` map
    (payload[schema][payload_key].columns), and emits the full `select ... from ...` body --
    present columns pass through, quoted, under their current name; absent columns get
    `cast(null as datatype)`. Mirrors fivetran_utils.fill_staging_columns' own branching (and
    its `alias` support) but driven by the payload instead of adapter.get_columns_in_relation,
    so no introspection is needed.

    salesforce__source_config is keyed by the connector's own immutable *source* field/table
    names (e.g. Salesforce API names like `AccountNumber`), not our destination/canonical
    names -- per the design agreed in GA-1038188 (see STAGING_V2_POC_NOTES.md). Destination
    names aren't a stable key: they shift with feature flags, connection settings, and
    customer renames, but the source name a field was synced from never changes. Each table
    entry is `{name: ..., columns: {SourceFieldName: current_destination_name, ...}}` -- the
    `name` key is reserved for a future identifier migration (also GA-1038188) and is NOT read
    here; table identifiers still come from the separate var()-based `identifier:` configs.

    A column's source field name is computed from its canonical `name` via
    `name.split('_') | map('capitalize') | join('')` (e.g. `account_number` ->
    `AccountNumber`) -- the exact same guess the now-retired `add_renamed_columns` macro used
    to make, which this package's own column lists never needed an explicit override for,
    across every table, in years of production use. Pass `source_name` on a column dict
    (alongside `name`/`datatype`) only if a future column's real API name doesn't follow that
    pattern. Fivetran metadata columns (any `name` containing `fivetran`) skip this lookup
    entirely -- they're synthetic, Fivetran-added, never renamed, and always present.

    A present column's current name is always quoted (quote_column with quote=true), not
    passed through bare: the payload can supply any spelling a connector actually produced
    (e.g. raw camelCase like `AccountNumber`), and most warehouses fold an *unquoted*
    identifier to their own default case (Postgres/Redshift to lowercase, Snowflake to
    uppercase) rather than preserving whatever case dbt seed/the connector actually created the
    column with. Confirmed directly: real dbt-core against real Postgres failed with `column
    "accountnumber" does not exist` (the physical column was `AccountNumber`, case-preserved)
    until this was quoted. Quoting a plain lowercase/underscore name this same way is a no-op
    on every warehouse, so there's no cost for the common (unrenamed) case.

    payload_key defaults to the PascalCase form of table_name (via the same transform as
    above, e.g. `opportunity_line_item` -> `OpportunityLineItem`) -- pass it explicitly only
    when two different sources' tables would otherwise share the same key (e.g. the
    salesforce_history source's `account` table vs. the core `salesforce` source's own
    `account` table): pass a distinct key like 'AccountHistory' so the two don't collide in
    the payload dict.

    source(source_name, table_name) is the only tie back to the source yml dbt itself
    understands -- it's what makes docs, lineage, and `dbt source freshness` work, and its
    `identifier:` is the plain var()-based config main has always had. This macro's FROM
    clause just reads from it directly -- no override of any kind.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.select_payload_fields('salesforce', 'campaign_member', get_campaign_member_columns()) }}
        ),
#}
{%- set payload_key = payload_key or (table_name.split('_') | map('capitalize') | join('')) -%}
{%- set table_source = source(source_name, table_name) -%}
{%- set full_source_config = var('salesforce__source_config', {}) or {} -%}
{%- if full_source_config | length == 1 -%}
    {%- set schema_config = full_source_config.values() | first -%}
{%- else -%}
    {%- set schema_config = full_source_config.get(table_source.schema | lower, {}) -%}
{%- endif -%}
{%- set column_config = ((schema_config or {}).get(payload_key, {}) or {}).get('columns', {}) or {} -%}

    select
        {%- for column in staging_columns %}
        {%- if 'fivetran' in column.name %}
            {{ fivetran_utils.quote_column({"name": column.name, "quote": true}) }} as {{ fivetran_utils.quote_column(column) }}
        {%- else %}
        {%- set source_field = column.source_name | default(column.name.split('_') | map('capitalize') | join('')) %}
        {%- set current_name = column_config.get(source_field) %}
        {%- if current_name is not none %}
            {{ fivetran_utils.quote_column({"name": current_name, "quote": true}) }} as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- else %}
            cast(null as {{ column.datatype }}) as
            {%- if 'alias' in column %} {{ column.alias }}{% else %} {{ fivetran_utils.quote_column(column) }}{% endif %}
        {%- endif %}
        {%- endif %}{{ ',' if not loop.last }}
        {%- endfor %}

    from {{ table_source }}

{%- endmacro %}
