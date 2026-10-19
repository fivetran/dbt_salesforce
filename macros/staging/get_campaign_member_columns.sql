
{% macro get_campaign_member_columns() %}

{% set columns = [
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "campaign_id", "source_name": "CampaignId", "datatype": dbt.type_string()},
    {"name": "contact_id", "source_name": "ContactId", "datatype": dbt.type_string()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "first_responded_date", "source_name": "FirstRespondedDate", "datatype": dbt.type_timestamp()},
    {"name": "has_opted_out_of_email", "source_name": "HasOptedOutOfEmail", "datatype": "boolean"},
    {"name": "has_responded", "source_name": "HasResponded", "datatype": "boolean"},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "lead_id", "source_name": "LeadId", "datatype": dbt.type_string()},
    {"name": "lead_or_contact_id", "source_name": "LeadOrContactId", "datatype": dbt.type_string()},
    {"name": "lead_or_contact_owner_id", "source_name": "LeadOrContactOwnerId", "datatype": dbt.type_string()},
    {"name": "status", "source_name": "Status", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__campaign_member_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
