
{% macro get_record_type_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "developer_name", "source_name": "DeveloperName", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_active", "source_name": "IsActive", "datatype": "boolean"},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "namespace_prefix", "source_name": "NamespacePrefix", "datatype": dbt.type_string()},
    {"name": "sobject_type", "source_name": "SobjectType", "datatype": dbt.type_string()}
] %}


{{ return(columns) }}

{% endmacro %}
