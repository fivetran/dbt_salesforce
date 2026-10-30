{% macro get_contact_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "department", "source_name": "Department", "datatype": dbt.type_string()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "email", "source_name": "Email", "datatype": dbt.type_string()},
    {"name": "first_name", "source_name": "FirstName", "datatype": dbt.type_string()},
    {"name": "home_phone", "source_name": "HomePhone", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "individual_id", "source_name": "IndividualId", "datatype": dbt.type_string()},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "last_activity_date", "source_name": "LastActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_name", "source_name": "LastName", "datatype": dbt.type_string()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "lead_source", "source_name": "LeadSource", "datatype": dbt.type_string()},
    {"name": "mailing_city", "source_name": "MailingCity", "datatype": dbt.type_string()},
    {"name": "mailing_country", "source_name": "MailingCountry", "datatype": dbt.type_string()},
    {"name": "mailing_country_code", "source_name": "MailingCountryCode", "datatype": dbt.type_string()},
    {"name": "mailing_postal_code", "source_name": "MailingPostalCode", "datatype": dbt.type_string()},
    {"name": "mailing_state", "source_name": "MailingState", "datatype": dbt.type_string()},
    {"name": "mailing_state_code", "source_name": "MailingStateCode", "datatype": dbt.type_string()},
    {"name": "mailing_street", "source_name": "MailingStreet", "datatype": dbt.type_string()},
    {"name": "master_record_id", "source_name": "MasterRecordId", "datatype": dbt.type_string()},
    {"name": "mobile_phone", "source_name": "MobilePhone", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "phone", "source_name": "Phone", "datatype": dbt.type_string()},
    {"name": "reports_to_id", "source_name": "ReportsToId", "datatype": dbt.type_string()},
    {"name": "title", "source_name": "Title", "datatype": dbt.type_string()},
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__contact_pass_through_columns')) }}        

{{ return(columns) }}

{% endmacro %}
