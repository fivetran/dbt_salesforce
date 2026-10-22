{% macro get_order_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "activated_by_id", "source_name": "ActivatedById", "datatype": dbt.type_string()},
    {"name": "activated_date", "source_name": "ActivatedDate", "datatype": dbt.type_timestamp()},
    {"name": "billing_city", "source_name": "BillingCity", "datatype": dbt.type_string()},
    {"name": "billing_country", "source_name": "BillingCountry", "datatype": dbt.type_string()},
    {"name": "billing_country_code", "source_name": "BillingCountryCode", "datatype": dbt.type_string()},
    {"name": "billing_postal_code", "source_name": "BillingPostalCode", "datatype": dbt.type_string()},
    {"name": "billing_state", "source_name": "BillingState", "datatype": dbt.type_string()},
    {"name": "billing_state_code", "source_name": "BillingStateCode", "datatype": dbt.type_string()},
    {"name": "billing_street", "source_name": "BillingStreet", "datatype": dbt.type_string()},
    {"name": "contract_id", "source_name": "ContractId", "datatype": dbt.type_string()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "end_date", "source_name": "EndDate", "datatype": dbt.type_timestamp()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "opportunity_id", "source_name": "OpportunityId", "datatype": dbt.type_string()},
    {"name": "order_number", "source_name": "OrderNumber", "datatype": dbt.type_string()},
    {"name": "original_order_id", "source_name": "OriginalOrderId", "datatype": dbt.type_string()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "pricebook_2_id", "source_name": "Pricebook2Id", "datatype": dbt.type_string()},
    {"name": "shipping_city", "source_name": "ShippingCity", "datatype": dbt.type_string()},
    {"name": "shipping_country", "source_name": "ShippingCountry", "datatype": dbt.type_string()},
    {"name": "shipping_country_code", "source_name": "ShippingCountryCode", "datatype": dbt.type_string()},
    {"name": "shipping_postal_code", "source_name": "ShippingPostalCode", "datatype": dbt.type_string()},
    {"name": "shipping_state", "source_name": "ShippingState", "datatype": dbt.type_string()},
    {"name": "shipping_state_code", "source_name": "ShippingStateCode", "datatype": dbt.type_string()},
    {"name": "shipping_street", "source_name": "ShippingStreet", "datatype": dbt.type_string()},
    {"name": "status", "source_name": "Status", "datatype": dbt.type_string()},
    {"name": "total_amount", "source_name": "TotalAmount", "datatype": dbt.type_float()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()},
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__order_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
