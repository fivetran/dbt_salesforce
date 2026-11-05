{% macro resolve_source_columns(source_name, table_name, staging_columns, payload_key, default_sync_mode='legacy') %}
{#
    Resolves staging columns from `salesforce__source_config` (keyed by connection schema or
    source name, then API object name) instead of warehouse introspection. Unmapped columns use
    their canonical or API name per `naming_standard`; `<fivetran_not_synced>` columns become
    typed nulls. Metadata columns that the table's `sync_mode` (default Legacy) doesn't add are
    derived from the ones it does, or nulled when there's no equivalent.
    `fivetran_packages_using_introspective_queries: true` restores the live lookup instead.
#}
{%- set table_source = source(source_name, table_name) -%}

{%- if var('fivetran_packages_using_introspective_queries', false) -%}

    {%- set present_columns = adapter.get_columns_in_relation(table_source) -%}
    {%- set resolved_columns = staging_columns -%}

{%- else -%}

    {# `or {}` guards against keys present but empty in YAML (e.g. a bare `columns:`), which .get() defaults don't cover #}
    {%- set full_config = var('salesforce__source_config', {}) or {} -%}
    {%- set source_config = full_config.get(table_source.schema) or full_config.get(source_name, {}) or {} -%}
    {%- set table_config = source_config.get(payload_key, {}) or {} -%}
    {%- set column_config = table_config.get('columns', {}) or {} -%}
    {%- set naming_standard = source_config.get('naming_standard', 'fivetran') -%}

    {# each sync mode adds its own metadata columns #}
    {# values match what Quickstart sends (Legacy, History, Live), case-insensitive; Legacy is soft delete mode #}
    {%- set raw_sync_mode = table_config.get('sync_mode') or source_config.get('sync_mode') or default_sync_mode -%}
    {%- set sync_mode = raw_sync_mode | string | lower -%}
    {%- set sync_mode_columns = {
        'legacy': ['_fivetran_deleted'],
        'history': ['_fivetran_active', '_fivetran_start', '_fivetran_end'],
        'live': []
    } -%}
    {%- if sync_mode not in sync_mode_columns -%}
        {{ exceptions.raise_compiler_error("Invalid sync_mode '" ~ raw_sync_mode ~ "' for " ~ source_name ~ "." ~ payload_key ~ " in salesforce__source_config. Use Legacy (soft delete), History, or Live.") }}
    {%- endif -%}
    {#
        Metadata columns a mode doesn't add are derived from the ones it does (each mode adds its
        columns to every table): soft-deleted or inactive rows read as not active, and live mode
        hard-deletes, so every row is active. _fivetran_start/_end have no equivalent outside history.
    #}
    {%- set derived_metadata = {
        'legacy': {'_fivetran_active': 'not coalesce(_fivetran_deleted, false)'},
        'history': {'_fivetran_deleted': 'not coalesce(_fivetran_active, true)'},
        'live': {'_fivetran_active': 'true', '_fivetran_deleted': 'false'}
    }[sync_mode] -%}
    {%- set mode_metadata_columns = ['_fivetran_deleted', '_fivetran_active', '_fivetran_start', '_fivetran_end'] -%}

    {%- set present_columns = [] -%}
    {%- set resolved_columns = [] -%}
    {%- set derived_columns = [] -%}

    {%- for column in staging_columns -%}
        {# metadata columns have no source_name, so they fall back to their canonical name #}
        {%- set field_name = column.get('source_name', column.name) -%}
        {%- if column.name in derived_metadata and field_name not in column_config -%}
            {%- do derived_columns.append('cast(' ~ derived_metadata[column.name] ~ ' as ' ~ column.datatype ~ ') as ' ~ column.get('alias', column.name)) -%}
        {%- else -%}
            {%- if column.name in mode_metadata_columns and column.name not in sync_mode_columns[sync_mode] -%}
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
        {%- endif -%}
    {%- endfor -%}

{%- endif -%}

    select
        {{ fivetran_utils.fill_staging_columns(
            source_columns=present_columns,
            staging_columns=resolved_columns
        ) }}
        {%- for derived in derived_columns|default([]) %},
        {{ derived }}
        {%- endfor %}
    from {{ table_source }}

{%- endmacro %}
