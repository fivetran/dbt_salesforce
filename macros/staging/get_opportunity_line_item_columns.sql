{% macro get_opportunity_line_item_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "discount", "source_name": "Discount", "datatype": dbt.type_float()},
    {"name": "has_quantity_schedule", "source_name": "HasQuantitySchedule", "datatype": "boolean"},
    {"name": "has_revenue_schedule", "source_name": "HasRevenueSchedule", "datatype": "boolean"},
    {"name": "has_schedule", "source_name": "HasSchedule", "datatype": "boolean"},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "list_price", "source_name": "ListPrice", "datatype": dbt.type_float()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "opportunity_id", "source_name": "OpportunityId", "datatype": dbt.type_string()},
    {"name": "pricebook_entry_id", "source_name": "PricebookEntryId", "datatype": dbt.type_string()},
    {"name": "product_2_id", "source_name": "Product2Id", "datatype": dbt.type_string()},
    {"name": "product_code", "source_name": "ProductCode", "datatype": dbt.type_string()},
    {"name": "quantity", "source_name": "Quantity", "datatype": dbt.type_float()},
    {"name": "service_date", "source_name": "ServiceDate", "datatype": dbt.type_timestamp()},
    {"name": "sort_order", "source_name": "SortOrder", "datatype": dbt.type_int()},
    {"name": "total_price", "source_name": "TotalPrice", "datatype": dbt.type_float()},
    {"name": "unit_price", "source_name": "UnitPrice", "datatype": dbt.type_float()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__opportunity_line_item_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
