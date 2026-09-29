{% macro get_campaign_member_columns() %}

{% set columns = [
    {"name": "account_id", "datatype": dbt.type_string()},
    {"name": "campaign_id", "datatype": dbt.type_string()},
    {"name": "contact_id", "datatype": dbt.type_string()},
    {"name": "created_by_id", "datatype": dbt.type_string()},
    {"name": "created_date", "datatype": dbt.type_timestamp()},
    {"name": "first_responded_date", "datatype": dbt.type_timestamp()},
    {"name": "has_opted_out_of_email", "datatype": "boolean"},
    {"name": "has_responded", "datatype": "boolean"},
    {"name": "id", "datatype": dbt.type_string(), "alias": "campaign_member_id"},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "last_modified_by_id", "datatype": dbt.type_string()},
    {"name": "lead_id", "datatype": dbt.type_string()},
    {"name": "lead_or_contact_id", "datatype": dbt.type_string()},
    {"name": "lead_or_contact_owner_id", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_member_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
