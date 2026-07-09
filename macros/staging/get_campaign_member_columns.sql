
{% macro get_campaign_member_columns() %}

{% set columns = [
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "campaign_id", "datatype": dbt.type_string()},
    {"name": "contact_id", "datatype": dbt.type_string()},
    {"name": "created_date", "datatype": dbt.type_timestamp()},
    {"name": "first_responded_date", "datatype": dbt.type_timestamp()},
    {"name": "has_responded", "datatype": "boolean"},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "lead_id", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()}
] %}

{{ salesforce.add_renamed_columns(columns) }}

{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_member_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
