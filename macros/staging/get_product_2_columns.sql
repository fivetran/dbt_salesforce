{% macro get_product_2_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "display_url", "source_name": "DisplayUrl", "datatype": dbt.type_string()},
    {"name": "external_id", "source_name": "ExternalId", "datatype": dbt.type_string()},
    {"name": "family", "source_name": "Family", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_active", "source_name": "IsActive", "datatype": "boolean"},
    {"name": "is_archived", "source_name": "IsArchived", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "number_of_quantity_installments", "source_name": "NumberOfQuantityInstallments", "datatype": dbt.type_int()},
    {"name": "number_of_revenue_installments", "source_name": "NumberOfRevenueInstallments", "datatype": dbt.type_int()},
    {"name": "product_code", "source_name": "ProductCode", "datatype": dbt.type_string()},
    {"name": "quantity_installment_period", "source_name": "QuantityInstallmentPeriod", "datatype": dbt.type_string()},
    {"name": "quantity_schedule_type", "source_name": "QuantityScheduleType", "datatype": dbt.type_string()},
    {"name": "quantity_unit_of_measure", "source_name": "QuantityUnitOfMeasure", "datatype": dbt.type_string()},
    {"name": "record_type_id", "source_name": "RecordTypeId", "datatype": dbt.type_string()},
    {"name": "revenue_installment_period", "source_name": "RevenueInstallmentPeriod", "datatype": dbt.type_string()},
    {"name": "revenue_schedule_type", "source_name": "RevenueScheduleType", "datatype": dbt.type_string()},
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__product_2_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
