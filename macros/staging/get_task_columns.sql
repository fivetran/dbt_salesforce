{% macro get_task_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "activity_date", "source_name": "ActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "call_disposition", "source_name": "CallDisposition", "datatype": dbt.type_string()},
    {"name": "call_duration_in_seconds", "source_name": "CallDurationInSeconds", "datatype": dbt.type_int()},
    {"name": "call_object", "source_name": "CallObject", "datatype": dbt.type_string()},
    {"name": "call_type", "source_name": "CallType", "datatype": dbt.type_string()},
    {"name": "completed_date_time", "source_name": "CompletedDateTime", "datatype": dbt.type_timestamp()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_archived", "source_name": "IsArchived", "datatype": "boolean"},
    {"name": "is_closed", "source_name": "IsClosed", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "is_high_priority", "source_name": "IsHighPriority", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "priority", "source_name": "Priority", "datatype": dbt.type_string()},
    {"name": "record_type_id", "source_name": "RecordTypeId", "datatype": dbt.type_string()},
    {"name": "status", "source_name": "Status", "datatype": dbt.type_string()},
    {"name": "subject", "source_name": "Subject", "datatype": dbt.type_string()},
    {"name": "task_subtype", "source_name": "TaskSubtype", "datatype": dbt.type_string()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()},
    {"name": "what_count", "source_name": "WhatCount", "datatype": dbt.type_int()},
    {"name": "what_id", "source_name": "WhatId", "datatype": dbt.type_string()},
    {"name": "who_count", "source_name": "WhoCount", "datatype": dbt.type_int()},
    {"name": "who_id", "source_name": "WhoId", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__task_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
