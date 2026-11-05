{% macro get_sync_mode(source_name, table_name, payload_key, default_sync_mode='legacy') %}
{#
    Returns the table's Fivetran sync mode from `salesforce__source_config` (table, then source,
    then `default_sync_mode`), lowercased: legacy (soft delete), history, or live. Values match what
    Quickstart sends (Legacy, History, Live), case-insensitive.
#}
{%- set table_source = source(source_name, table_name) -%}
{%- set full_config = var('salesforce__source_config', {}) or {} -%}
{%- set source_config = full_config.get(table_source.schema) or full_config.get(source_name, {}) or {} -%}
{%- set table_config = source_config.get(payload_key, {}) or {} -%}
{%- set raw_sync_mode = table_config.get('sync_mode') or source_config.get('sync_mode') or default_sync_mode -%}
{%- set sync_mode = raw_sync_mode | string | lower -%}
{%- if sync_mode not in ['legacy', 'history', 'live'] -%}
    {{ exceptions.raise_compiler_error("Invalid sync_mode '" ~ raw_sync_mode ~ "' for " ~ source_name ~ "." ~ payload_key ~ " in salesforce__source_config. Use Legacy (soft delete), History, or Live.") }}
{%- endif -%}
{{ return(sync_mode) }}
{%- endmacro %}
