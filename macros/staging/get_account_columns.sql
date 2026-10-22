{% macro get_account_columns() %}

{% set columns = [

    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "account_number", "source_name": "AccountNumber", "datatype": dbt.type_string()},
    {"name": "account_source", "source_name": "AccountSource", "datatype": dbt.type_string()},
    {"name": "annual_revenue", "source_name": "AnnualRevenue", "datatype": dbt.type_float()},
    {"name": "billing_city", "source_name": "BillingCity", "datatype": dbt.type_string()},
    {"name": "billing_country", "source_name": "BillingCountry", "datatype": dbt.type_string()},
    {"name": "billing_postal_code", "source_name": "BillingPostalCode", "datatype": dbt.type_string()},
    {"name": "billing_state", "source_name": "BillingState", "datatype": dbt.type_string()},
    {"name": "billing_state_code", "source_name": "BillingStateCode", "datatype": dbt.type_string()},
    {"name": "billing_street", "source_name": "BillingStreet", "datatype": dbt.type_string()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "industry", "source_name": "Industry", "datatype": dbt.type_string()},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": dbt.type_boolean()},
    {"name": "last_activity_date", "source_name": "LastActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "master_record_id", "source_name": "MasterRecordId", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "number_of_employees", "source_name": "NumberOfEmployees", "datatype": dbt.type_int()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "ownership", "source_name": "Ownership", "datatype": dbt.type_string()},
    {"name": "parent_id", "source_name": "ParentId", "datatype": dbt.type_string()},
    {"name": "rating", "source_name": "Rating", "datatype": dbt.type_string()},
    {"name": "record_type_id", "source_name": "RecordTypeId", "datatype": dbt.type_string()},
    {"name": "shipping_city", "source_name": "ShippingCity", "datatype": dbt.type_string()},
    {"name": "shipping_country", "source_name": "ShippingCountry", "datatype": dbt.type_string()},
    {"name": "shipping_country_code", "source_name": "ShippingCountryCode", "datatype": dbt.type_string()},
    {"name": "shipping_postal_code", "source_name": "ShippingPostalCode", "datatype": dbt.type_string()},
    {"name": "shipping_state", "source_name": "ShippingState", "datatype": dbt.type_string()},
    {"name": "shipping_state_code", "source_name": "ShippingStateCode", "datatype": dbt.type_string()},
    {"name": "shipping_street", "source_name": "ShippingStreet", "datatype": dbt.type_string()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()},
    {"name": "website", "source_name": "Website", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__account_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}