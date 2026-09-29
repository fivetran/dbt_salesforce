{% macro get_account_columns() %}

{% set columns = [

    {"name": "account_number", "datatype": dbt.type_string()},
    {"name": "account_source", "datatype": dbt.type_string()},
    {"name": "annual_revenue", "datatype": dbt.type_numeric()},
    {"name": "billing_city", "datatype": dbt.type_string()},
    {"name": "billing_country", "datatype": dbt.type_string()},
    {"name": "billing_postal_code", "datatype": dbt.type_string()},
    {"name": "billing_state", "datatype": dbt.type_string()},
    {"name": "billing_state_code", "datatype": dbt.type_string()},
    {"name": "billing_street", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string(), "alias": "account_description"},
    {"name": "id", "datatype": dbt.type_string(), "alias": "account_id"},
    {"name": "industry", "datatype": dbt.type_string()},
    {"name": "is_deleted", "datatype": dbt.type_boolean()},
    {"name": "last_activity_date", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "datatype": dbt.type_timestamp()},
    {"name": "master_record_id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string(), "alias": "account_name"},
    {"name": "number_of_employees", "datatype": dbt.type_int()},
    {"name": "owner_id", "datatype": dbt.type_string()},
    {"name": "ownership", "datatype": dbt.type_string()},
    {"name": "parent_id", "datatype": dbt.type_string()},
    {"name": "rating", "datatype": dbt.type_string()},
    {"name": "record_type_id", "datatype": dbt.type_string()},
    {"name": "shipping_city", "datatype": dbt.type_string()},
    {"name": "shipping_country", "datatype": dbt.type_string()},
    {"name": "shipping_country_code", "datatype": dbt.type_string()},
    {"name": "shipping_postal_code", "datatype": dbt.type_string()},
    {"name": "shipping_state", "datatype": dbt.type_string()},
    {"name": "shipping_state_code", "datatype": dbt.type_string()},
    {"name": "shipping_street", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "website", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__account_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
