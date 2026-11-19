{% macro get_source_node(source_name, table_name) %}
{# The source table's node from the graph; none at parse time, when the graph isn't populated #}
{%- set nodes = [] -%}
{%- if execute -%}
    {%- for node in graph.sources.values() if node.source_name == source_name and node.name == table_name -%}
        {%- do nodes.append(node) -%}
    {%- endfor -%}
{%- endif -%}
{{ return(nodes[0] if nodes else none) }}
{%- endmacro %}


{% macro get_source_table_name(source_name, table_name) %}
{# The table's Salesforce object name (`config.meta.source_table_name` in the source yml), used as its `salesforce__source_config` key #}
{%- set node = salesforce.get_source_node(source_name, table_name) -%}
{%- set table_meta = ((node.config or {}).get('meta') or node.meta or {}) if node else {} -%}
{{ return(table_meta.get('source_table_name', table_name)) }}
{%- endmacro %}
