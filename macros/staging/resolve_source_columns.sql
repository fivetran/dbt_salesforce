{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key) %}
{#
    Builds the full `select ... from ...` body for a model's `fields` CTE: present columns
    pass through, quoted, under their current name; absent columns get `cast(null as
    datatype)`. Driven entirely by the salesforce__source_config var, so no
    adapter.get_columns_in_relation introspection is needed. `identifier:` in the source yml
    stays plain var('salesforce_<table>_identifier', '<table>') -- untouched by this macro.

    The actual rendering is delegated to fivetran_utils.fill_staging_columns, which already
    implements "quote present column / cast null for absent / honor column.alias" and
    fivetran_using_source_casing (a documented Fivetran-wide var for the Managed Data Lake
    Service/Iceberg-on-Snowflake case) -- this macro's only job is building the two lists
    fill_staging_columns expects: present_columns (what's actually there, under its current
    name) and resolved_columns (staging_columns with `name` replaced by the current name and
    an explicit `alias` so the canonical name is always what's output, never the renamed one).

    salesforce__source_config is keyed by source_name (the dbt source() this table belongs to,
    e.g. `salesforce`/`salesforce_history` -- always one of the hardcoded literals every model
    already passes, never derived from a schema name or any other runtime-resolved value), then
    by TableKey using the connector's own source field/table names (e.g. Salesforce API names
    like `AccountNumber`), not this package's destination/canonical names, since those can be
    renamed per connection. Shape: `source_name -> TableKey -> {name: ..., columns:
    {SourceFieldName: current_destination_name}}`. The `name` key is not read here; table
    identifiers come from the separate `identifier:` vars.

    Keying by source_name rather than physical schema is deliberate: the two sources' schemas
    (salesforce_schema/salesforce_history_schema) are themselves just vars, so a schema-keyed
    config would need its own keys to track whatever those vars resolve to at runtime --
    fragile, and actively wrong in environments (like CI) that override both schema vars to the
    same dynamically-generated value. source_name has none of that: it's the same fixed string
    at every call site regardless of what schema that source happens to point at, so one source
    being customized never depends on knowing or matching the other's physical location.

    Any column not mentioned in a table's `columns` map -- whether the table has no entry at
    all, or has an entry but just doesn't list this particular field -- is assumed present
    under its own canonical name, the connector's documented default (unrenamed) behavior.
    A connection only needs an entry for a column that's actually renamed, or to
    explicitly flag one as missing with `SourceFieldName: <fivetran_not_synced>` (not
    omission -- omission means "present, default name"). The angle-bracket, `fivetran_`-
    prefixed spelling is deliberate: it's not a string any real destination column would
    plausibly be named, so it can't collide. This keeps a one-field customization a one-line
    change, not a requirement to exhaustively list every column in that table.

    Every non-metadata column dict in staging_columns must carry an explicit `source_name`
    (set alongside `name`/`datatype` in the get_*_columns macro) naming its real Salesforce
    API field -- not guessed or computed here. Fivetran metadata columns (any `name`
    containing `_fivetran`) skip the lookup entirely -- always present, never renamed, no
    `source_name` needed.

    payload_key is required and must match the key this table's entry uses in
    salesforce__source_config (its Salesforce API Object name, e.g. `OpportunityLineItem`,
    or a distinct variant like `AccountHistory` when two sources' tables would otherwise
    share a key, e.g. `account` in both `salesforce` and `salesforce_history`).

    A present column's current name is always quoted (quote_column with quote=true): most
    warehouses fold an unquoted identifier to their own default case, which can mismatch
    whatever case the connector actually produced. A no-op for plain lowercase/underscore
    names.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.resolve_source_columns(source_name='salesforce', table_name='campaign_member', staging_columns=salesforce.get_campaign_member_columns(), payload_key='CampaignMember') }}
        ),
#}
{%- set table_source = source(source_name, table_name) -%}
{# the whole payload var, defaulting to {} if the connection never set it #}
{%- set full_source_config = var('salesforce__source_config', {}) or {} -%}
{# this source's own config, defaulting to {} if it's missing entirely #}
{%- set source_config = full_source_config.get(source_name, {}) or {} -%}
{# this table's own entry, defaulting to {} whether it's missing entirely or just has no columns map #}
{%- set column_config = ((source_config or {}).get(payload_key, {}) or {}).get('columns', {}) or {} -%}

{# build what fill_staging_columns expects: a list of columns that are actually "present"
   (keyed by their current name, so its own name|lower membership check matches), and the
   staging_columns list with `name` swapped to the current name and `alias` always explicit
   so the canonical name is what's output, never the renamed one #}
{%- set present_columns = [] -%}
{%- set resolved_columns = [] -%}
{%- for column in staging_columns -%}
    {%- if '_fivetran' in column.name -%}
        {%- set resolved = column.copy() -%}
        {%- do resolved.update({'quote': true}) -%}
        {%- do resolved_columns.append(resolved) -%}
        {%- do present_columns.append({'name': column.name}) -%}
    {%- else -%}
        {# unmentioned columns default to their own canonical name; <fivetran_not_synced> is the explicit missing-field flag #}
        {%- set current_name = column_config.get(column.source_name, column.name) -%}
        {%- set resolved = column.copy() -%}
        {%- do resolved.update({
            'name': current_name,
            'alias': column.alias if 'alias' in column else column.name,
            'quote': current_name != column.name
        }) -%}
        {%- do resolved_columns.append(resolved) -%}
        {%- if current_name != '<fivetran_not_synced>' -%}
            {%- do present_columns.append({'name': current_name}) -%}
        {%- endif -%}
    {%- endif -%}
{%- endfor -%}

    select
        {{ fivetran_utils.fill_staging_columns(source_columns=present_columns, staging_columns=resolved_columns) }}

    from {{ table_source }}

{%- endmacro %}
