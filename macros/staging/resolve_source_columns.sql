{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key) %}
{#
    Builds the full `select ... from ...` body for a model's `fields` CTE: present columns
    pass through, quoted, under their current name; absent columns get `cast(null as
    datatype)`. Driven entirely by the salesforce__source_config var, so no
    adapter.get_columns_in_relation introspection is needed. `identifier:` in the source yml
    stays plain var('salesforce_<table>_identifier', '<table>') -- untouched by this macro.

    salesforce__source_config is keyed by the connector's own source field/table names (e.g.
    Salesforce API names like `AccountNumber`), not this package's destination/canonical
    names, since those can be renamed per customer. Shape: `schema -> TableKey ->
    {name: ..., columns: {SourceFieldName: current_destination_name}}`. The `name` key is not
    read here; table identifiers come from the separate `identifier:` vars.

    Every non-metadata column dict in staging_columns must carry an explicit `source_name`
    (set alongside `name`/`datatype` in the get_*_columns macro) naming its real Salesforce
    API field -- not guessed or computed here. Fivetran metadata columns (any `name`
    containing `fivetran`) skip the lookup entirely -- always present, never renamed, no
    `source_name` needed.

    payload_key is required and must match the key this table's entry uses in
    salesforce__source_config (its Salesforce API SObject name, e.g. `OpportunityLineItem`,
    or a distinct variant like `AccountHistory` when two sources' tables would otherwise
    share a key, e.g. `account` in both `salesforce` and `salesforce_history`).

    A present column's current name is always quoted (quote_column with quote=true): most
    warehouses fold an unquoted identifier to their own default case, which can mismatch
    whatever case the connector actually produced. A no-op for plain lowercase/underscore
    names.

    Usage in a model's `fields` CTE:
        with fields as (
            {{ salesforce.resolve_source_columns('salesforce', 'campaign_member', salesforce.get_campaign_member_columns(), payload_key='CampaignMember') }}
        ),
#}
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
        {%- set current_name = column_config.get(column.source_name) %}
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
