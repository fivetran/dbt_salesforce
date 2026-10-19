
{% macro get_opportunity_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "amount", "source_name": "Amount", "datatype": dbt.type_float()},
    {"name": "campaign_id", "source_name": "CampaignId", "datatype": dbt.type_string()},
    {"name": "close_date", "source_name": "CloseDate", "datatype": dbt.type_timestamp()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "expected_revenue", "source_name": "ExpectedRevenue", "datatype": dbt.type_numeric()},
    {"name": "fiscal", "source_name": "Fiscal", "datatype": dbt.type_string()},
    {"name": "fiscal_quarter", "source_name": "FiscalQuarter", "datatype": dbt.type_int()},
    {"name": "fiscal_year", "source_name": "FiscalYear", "datatype": dbt.type_int()},
    {"name": "forecast_category", "source_name": "ForecastCategory", "datatype": dbt.type_string()},
    {"name": "forecast_category_name", "source_name": "ForecastCategoryName", "datatype": dbt.type_string()},
    {"name": "has_open_activity", "source_name": "HasOpenActivity", "datatype": "boolean"},
    {"name": "has_opportunity_line_item", "source_name": "HasOpportunityLineItem", "datatype": "boolean"},
    {"name": "has_overdue_task", "source_name": "HasOverdueTask", "datatype": "boolean"},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_closed", "source_name": "IsClosed", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "is_won", "source_name": "IsWon", "datatype": "boolean"},
    {"name": "last_activity_date", "source_name": "LastActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "lead_source", "source_name": "LeadSource", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "next_step", "source_name": "NextStep", "datatype": dbt.type_string()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "probability", "source_name": "Probability", "datatype": dbt.type_float()},
    {"name": "record_type_id", "source_name": "RecordTypeId", "datatype": dbt.type_string()},
    {"name": "stage_name", "source_name": "StageName", "datatype": dbt.type_string()},
    {"name": "synced_quote_id", "source_name": "SyncedQuoteId", "datatype": dbt.type_string()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__opportunity_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}