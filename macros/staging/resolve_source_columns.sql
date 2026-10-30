{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key) %}
{#
    Resolves staging columns using `salesforce__source_config` instead of warehouse
    introspection, supporting renamed and unsynced columns.

    Configuration:
    - Keyed by dbt source name, then Salesforce API object name (`payload_key`).
    - Column mappings use Salesforce API field names (`source_name`).
    - Unmapped columns default to their canonical name (`naming_standard: fivetran`)
      or API field name (`naming_standard: source`).
    - Explicit mappings override either naming standard.
    - Use `<fivetran_not_synced>` to mark missing columns; omitted mappings are
      assumed present.
    - Metadata columns use their canonical names for lookup.

    Present columns are selected under their canonical aliases; missing columns
    are filled with typed nulls via `fivetran_utils.fill_staging_columns`.

    Set `fivetran_packages_using_introspective_queries: true` to restore legacy
    column detection, bypassing the config. This does not restore the previous
    camelCase/snake_case coalescing behavior.

    Table identifiers remain controlled by their existing source YAML vars.
#}
{%- set table_source = source(source_name, table_name) -%}

{%- if var('fivetran_packages_using_introspective_queries', false) -%}

    select
        {{ fivetran_utils.fill_staging_columns(
            source_columns=adapter.get_columns_in_relation(table_source),
            staging_columns=staging_columns
        ) }}
    from {{ table_source }}

{%- else -%}

    {# `or {}` guards against keys present but empty in YAML (e.g. a bare `columns:`), which .get() defaults don't cover #}
    {%- set source_config = (var('salesforce__source_config', {}) or {}).get(source_name, {}) or {} -%}
    {%- set column_config = ((source_config.get(payload_key, {}) or {}).get('columns', {})) or {} -%}
    {%- set naming_standard = source_config.get('naming_standard', 'fivetran') -%}

    {%- set present_columns = [] -%}
    {%- set resolved_columns = [] -%}

    {%- for column in staging_columns -%}
        {# metadata columns have no source_name, so they fall back to their canonical name #}
        {%- set field_name = column.get('source_name', column.name) -%}
        {%- set default_name = field_name if naming_standard == 'source' else column.name -%}
        {%- set current_name = column_config.get(field_name, default_name) -%}

        {%- set resolved = column.copy() -%}
        {%- do resolved.update({
            'name': current_name,
            'alias': column.get('alias', column.name),
            'quote': current_name != column.name
        }) -%}
        {%- do resolved_columns.append(resolved) -%}

        {%- if current_name != '<fivetran_not_synced>' -%}
            {%- do present_columns.append({'name': current_name}) -%}
        {%- endif -%}
    {%- endfor -%}

    select
        {{ fivetran_utils.fill_staging_columns(
            source_columns=present_columns,
            staging_columns=resolved_columns
        ) }}
    from {{ table_source }}

{%- endif -%}

{%- endmacro %}
