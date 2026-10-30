
{% macro get_campaign_columns() %}

{% set columns = [
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "actual_cost", "source_name": "ActualCost", "datatype": dbt.type_numeric()},
    {"name": "amount_all_opportunities", "source_name": "AmountAllOpportunities", "datatype": dbt.type_numeric()},
    {"name": "budgeted_cost", "source_name": "BudgetedCost", "datatype": dbt.type_numeric()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "end_date", "source_name": "EndDate", "datatype": dbt.type_timestamp()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_active", "source_name": "IsActive", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "number_of_contacts", "source_name": "NumberOfContacts", "datatype": dbt.type_int()},
    {"name": "number_of_converted_leads", "source_name": "NumberOfConvertedLeads", "datatype": dbt.type_int()},
    {"name": "number_of_leads", "source_name": "NumberOfLeads", "datatype": dbt.type_int()},
    {"name": "number_of_opportunities", "source_name": "NumberOfOpportunities", "datatype": dbt.type_int()},
    {"name": "number_of_responses", "source_name": "NumberOfResponses", "datatype": dbt.type_int()},
    {"name": "number_of_won_opportunities", "source_name": "NumberOfWonOpportunities", "datatype": dbt.type_int()},
    {"name": "campaign_member_record_type_id", "source_name": "CampaignMemberRecordTypeId", "datatype": dbt.type_string()},
    {"name": "parent_id", "source_name": "ParentId", "datatype": dbt.type_string()},
    {"name": "start_date", "source_name": "StartDate", "datatype": dbt.type_timestamp()},
    {"name": "status", "source_name": "Status", "datatype": dbt.type_string()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
