{% macro get_record_type_columns() %}

{% set columns = [
    {"name": "description", "datatype": dbt.type_string(), "alias": "record_type_description"},
    {"name": "developer_name", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string(), "alias": "record_type_id"},
    {"name": "is_active", "datatype": "boolean"},
    {"name": "name", "datatype": dbt.type_string(), "alias": "record_type_name"},
    {"name": "namespace_prefix", "datatype": dbt.type_string()},
    {"name": "sobject_type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
