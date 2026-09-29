{% macro get_campaign_columns() %}

{% set columns = [
    {"name": "actual_cost", "datatype": dbt.type_numeric()},
    {"name": "amount_all_opportunities", "datatype": dbt.type_numeric(), "alias": "total_pipeline_amount"},
    {"name": "budgeted_cost", "datatype": dbt.type_numeric()},
    {"name": "description", "datatype": dbt.type_string(), "alias": "campaign_description"},
    {"name": "end_date", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string(), "alias": "campaign_id"},
    {"name": "is_active", "datatype": "boolean"},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "name", "datatype": dbt.type_string(), "alias": "campaign_name"},
    {"name": "number_of_contacts", "datatype": dbt.type_int()},
    {"name": "number_of_converted_leads", "datatype": dbt.type_int()},
    {"name": "number_of_leads", "datatype": dbt.type_int()},
    {"name": "number_of_opportunities", "datatype": dbt.type_int()},
    {"name": "number_of_responses", "datatype": dbt.type_int()},
    {"name": "number_of_won_opportunities", "datatype": dbt.type_int()},
    {"name": "campaign_member_record_type_id", "datatype": dbt.type_string()},
    {"name": "parent_id", "datatype": dbt.type_string(), "alias": "parent_campaign_id"},
    {"name": "start_date", "datatype": dbt.type_timestamp()},
    {"name": "status", "datatype": dbt.type_string(), "alias": "campaign_status"},
    {"name": "type", "datatype": dbt.type_string(), "alias": "campaign_type"}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
