{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key, default_sync_mode='legacy') %}
{#
    Resolves staging columns from `salesforce__source_config` instead of introspection.
    Unsynced columns, and metadata columns the sync mode doesn't add, become typed nulls.
#}
{%- set table_source = source(source_name, table_name) -%}

{%- if var('fivetran_packages_using_introspective_queries', false) -%}

    {%- set present_columns = adapter.get_columns_in_relation(table_source) -%}
    {%- set resolved_columns = staging_columns -%}

{%- else -%}

    {# `or {}` covers keys present but empty in YAML #}
    {%- set full_config = var('salesforce__source_config', {}) or {} -%}
    {%- set source_config = full_config.get(table_source.schema) or full_config.get(source_name, {}) or {} -%}
    {%- set table_config = source_config.get(payload_key, {}) or {} -%}
    {%- set column_config = table_config.get('columns', {}) or {} -%}
    {%- set naming_standard = source_config.get('naming_standard', 'fivetran') -%}

    {# metadata columns each mode adds: https://fivetran.com/docs/core-concepts/sync-modes #}
    {%- set sync_mode = salesforce.get_sync_mode(source_name, table_name, payload_key, default_sync_mode) -%}
    {%- set sync_mode_columns = {
        'legacy': ['_fivetran_deleted'],
        'history': ['_fivetran_active', '_fivetran_start', '_fivetran_end'],
        'live': []
    }[sync_mode] -%}
    {%- set mode_metadata_columns = ['_fivetran_deleted', '_fivetran_active', '_fivetran_start', '_fivetran_end'] -%}

    {# each column's `config.meta.source_column_name` from the source yml; graph is only populated at execution #}
    {%- set source_column_names = {} -%}
    {%- if execute -%}
        {%- for node in graph.sources.values() if node.source_name == source_name and node.name == table_name -%}
            {%- for column_name, source_column in node.columns.items() -%}
                {%- set column_meta = (source_column.get('config') or {}).get('meta') or source_column.get('meta') or {} -%}
                {%- if column_meta.get('source_column_name') -%}
                    {%- do source_column_names.update({column_name: column_meta.get('source_column_name')}) -%}
                {%- endif -%}
            {%- endfor -%}
        {%- endfor -%}
    {%- endif -%}

    {%- set present_columns = [] -%}
    {%- set resolved_columns = [] -%}

    {%- for column in staging_columns -%}
        {# metadata and pass-through columns have no source column name, so they fall back to their canonical name #}
        {%- set field_name = source_column_names.get(column.name, column.name) -%}
        {%- if column.name in mode_metadata_columns and column.name not in sync_mode_columns -%}
            {%- set default_name = '<fivetran_not_synced>' -%}
        {%- else -%}
            {%- set default_name = field_name if naming_standard == 'source' else column.name -%}
        {%- endif -%}
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
