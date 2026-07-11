
{% macro get_campaign_columns() %}

{% set columns = [
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "actual_cost", "datatype": dbt.type_numeric()},
    {"name": "amount_all_opportunities", "datatype": dbt.type_numeric()},
    {"name": "budgeted_cost", "datatype": dbt.type_numeric()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "end_date", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_active", "datatype": "boolean"},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "number_of_contacts", "datatype": dbt.type_int()},
    {"name": "number_of_converted_leads", "datatype": dbt.type_int()},
    {"name": "number_of_leads", "datatype": dbt.type_int()},
    {"name": "number_of_opportunities", "datatype": dbt.type_int()},
    {"name": "number_of_responses", "datatype": dbt.type_int()},
    {"name": "number_of_won_opportunities", "datatype": dbt.type_int()},
    {"name": "campaign_member_record_type_id", "datatype": dbt.type_string()},
    {"name": "parent_id", "datatype": dbt.type_string()},
    {"name": "start_date", "datatype": dbt.type_timestamp()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()}
] %}

{{ salesforce.add_renamed_columns(columns) }}

{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
