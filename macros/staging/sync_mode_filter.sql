{% macro sync_mode_filter(source_name, table_name, payload_key, default_sync_mode='legacy') %}
{#
    Filter that keeps current, undeleted rows, using the metadata column the table's sync mode adds:
    Legacy (soft delete) uses _fivetran_deleted, History uses _fivetran_active, and Live hard-deletes,
    so it keeps every row. With introspection the mode isn't known, so both checks are applied;
    a column the table lacks is a null and doesn't filter anything.
#}
{%- if var('fivetran_packages_using_introspective_queries', false) -%}
    coalesce(_fivetran_active, true) and not coalesce(_fivetran_deleted, false)
{%- else -%}
    {%- set sync_mode = salesforce.get_sync_mode(source_name, table_name, payload_key, default_sync_mode) -%}
    {%- if sync_mode == 'legacy' -%}
    not coalesce(_fivetran_deleted, false)
    {%- elif sync_mode == 'history' -%}
    coalesce(_fivetran_active, true)
    {%- else -%}
    true
    {%- endif -%}
{%- endif -%}
{%- endmacro %}
