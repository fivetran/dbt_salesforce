{% macro get_event_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "activity_date", "source_name": "ActivityDate", "datatype": dbt.type_timestamp()},
    {"name": "activity_date_time", "source_name": "ActivityDateTime", "datatype": dbt.type_timestamp()},
    {"name": "created_by_id", "source_name": "CreatedById", "datatype": dbt.type_string()},
    {"name": "created_date", "source_name": "CreatedDate", "datatype": dbt.type_timestamp()},
    {"name": "description", "source_name": "Description", "datatype": dbt.type_string()},
    {"name": "end_date", "source_name": "EndDate", "datatype": dbt.type_timestamp()},
    {"name": "end_date_time", "source_name": "EndDateTime", "datatype": dbt.type_timestamp()},
    {"name": "event_subtype", "source_name": "EventSubtype", "datatype": dbt.type_string()},
    {"name": "group_event_type", "source_name": "GroupEventType", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "is_archived", "source_name": "IsArchived", "datatype": "boolean"},
    {"name": "is_child", "source_name": "IsChild", "datatype": "boolean"},
    {"name": "is_deleted", "source_name": "IsDeleted", "datatype": "boolean"},
    {"name": "is_group_event", "source_name": "IsGroupEvent", "datatype": "boolean"},
    {"name": "is_recurrence", "source_name": "IsRecurrence", "datatype": "boolean"},
    {"name": "last_modified_by_id", "source_name": "LastModifiedById", "datatype": dbt.type_string()},
    {"name": "last_modified_date", "source_name": "LastModifiedDate", "datatype": dbt.type_timestamp()},
    {"name": "location", "source_name": "Location", "datatype": dbt.type_string()},
    {"name": "owner_id", "source_name": "OwnerId", "datatype": dbt.type_string()},
    {"name": "start_date_time", "source_name": "StartDateTime", "datatype": dbt.type_timestamp()},
    {"name": "subject", "source_name": "Subject", "datatype": dbt.type_string()},
    {"name": "type", "source_name": "Type", "datatype": dbt.type_string()},
    {"name": "what_count", "source_name": "WhatCount", "datatype": dbt.type_int()},
    {"name": "what_id", "source_name": "WhatId", "datatype": dbt.type_string()},
    {"name": "who_count", "source_name": "WhoCount", "datatype": dbt.type_int()},
    {"name": "who_id", "source_name": "WhoId", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__event_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
