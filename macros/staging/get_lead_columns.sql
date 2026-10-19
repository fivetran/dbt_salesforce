{% macro get_lead_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "annual_revenue", "source_name": "AnnualRevenue", "datatype": dbt.type_float()},
    {"name": "city", "source_name": "City", "datatype": dbt.type_string()},
    {"name": "company", "source_name": "Company", "datatype": dbt.type_string()},
    {"name": "converted_account_id", "source_name": "ConvertedAccountId", "datatype": dbt.type_string()},
    {"name": "converted_contact_id", "source_name": "ConvertedContactId", "datatype": dbt.type_string()},
    {"name": "converted_date", "source_name": "ConvertedDate", "datatype": dbt.type_timestamp()},
    {"name": "converted_opportunity_id", "source_name": "ConvertedOpportunityId", "datatype": dbt.type_string()},
    {"name": "country", "source_name": "Country", "datatype": dbt.type_string()},
    {"name": "country_code", "source_name": "CountryCode", "datatype": dbt.type_string()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "email", "source_name": "Email", "datatype": dbt.type_string()},
    {"name": "email_bounced_date", "source_name": "EmailBouncedDate", "datatype": dbt.type_timestamp()},
    {"name": "email_bounced_reason", "source_name": "EmailBouncedReason", "datatype": dbt.type_string()},
    {"name": "first_name", "source_name": "FirstName", "datatype": dbt.type_string()},
    {"name": "has_opted_out_of_email", "source_name": "HasOptedOutOfEmail", "datatype": "boolean"},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "individual_id", "source_name": "IndividualId", "datatype": dbt.type_string()},
    {"name": "industry", "source_name": "Industry", "datatype": dbt.type_string()},
    {"name": "is_converted", "source_name": "IsConverted", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "is_unread_by_owner", "source_name": "IsUnreadByOwner", "datatype": "boolean"},
    {"name": "last_activity_date", "source_name": "LastActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_name", "source_name": "LastName", "datatype": dbt.type_string()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "lead_source", "source_name": "LeadSource", "datatype": dbt.type_string()},
    {"name": "master_record_id", "source_name": "MasterRecordId", "datatype": dbt.type_string()},
    {"name": "mobile_phone", "source_name": "MobilePhone", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "number_of_employees", "source_name": "NumberOfEmployees", "datatype": dbt.type_int()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "phone", "source_name": "Phone", "datatype": dbt.type_string()},
    {"name": "postal_code", "source_name": "PostalCode", "datatype": dbt.type_string()},
    {"name": "state", "source_name": "State", "datatype": dbt.type_string()},
    {"name": "state_code", "source_name": "StateCode", "datatype": dbt.type_string()},
    {"name": "status", "source_name": "Status", "datatype": dbt.type_string()},
    {"name": "street", "source_name": "Street", "datatype": dbt.type_string()},
    {"name": "title", "source_name": "Title", "datatype": dbt.type_string()},
    {"name": "website", "source_name": "Website", "datatype": dbt.type_string()},
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__lead_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
