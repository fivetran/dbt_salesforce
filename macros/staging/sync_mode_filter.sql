{% macro sync_mode_filter(source_name, table_name, default_sync_mode='legacy') %}
{# Keeps current, undeleted rows using the column the sync mode adds; Live hard-deletes, so keeps all #}
{%- if var('fivetran_packages_using_introspective_queries', false) -%}
    {# mode unknown: apply both; a missing column is null #}
    coalesce(_fivetran_active, true) and not coalesce(_fivetran_deleted, false)
{%- else -%}
    {%- set sync_mode = salesforce.get_sync_mode(source_name, table_name, default_sync_mode) -%}
    {%- if sync_mode == 'legacy' -%}
    not coalesce(_fivetran_deleted, false)
    {%- elif sync_mode == 'history' -%}
    coalesce(_fivetran_active, true)
    {%- else -%}
    true
    {%- endif -%}
{%- endif -%}
{%- endmacro %}
