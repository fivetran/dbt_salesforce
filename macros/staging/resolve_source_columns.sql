{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key) %}
{#
    Resolves staging columns from `salesforce__source_config` (keyed by source name, then
    API object name) instead of warehouse introspection. Unmapped columns use their canonical
    or API name per `naming_standard`; `<fivetran_not_synced>` columns become typed nulls.
    `fivetran_packages_using_introspective_queries: true` restores the live lookup instead.
#}
{%- set table_source = source(source_name, table_name) -%}

{%- if var('fivetran_packages_using_introspective_queries', false) -%}

    {%- set present_columns = adapter.get_columns_in_relation(table_source) -%}
    {%- set resolved_columns = staging_columns -%}

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

{%- endif -%}

    select
        {{ fivetran_utils.fill_staging_columns(
            source_columns=present_columns,
            staging_columns=resolved_columns
        ) }}
    from {{ table_source }}

{%- endmacro %}
