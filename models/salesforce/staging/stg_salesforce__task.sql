--To disable this model, set the salesforce__task_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__task_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('task', get_task_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as task_id,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(activity_date as {{ dbt.type_timestamp() }}) as activity_date,
        cast(call_disposition as {{ dbt.type_string() }}) as call_disposition,
        cast(call_duration_in_seconds as {{ dbt.type_int() }}) as call_duration_in_seconds,
        cast(call_object as {{ dbt.type_string() }}) as call_object,
        cast(call_type as {{ dbt.type_string() }}) as call_type,
        cast(completed_date_time as {{ dbt.type_timestamp() }}) as completed_date_time,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as task_description,
        cast(is_archived as {{ "boolean" }}) as is_archived,
        cast(is_closed as {{ "boolean" }}) as is_closed,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(is_high_priority as {{ "boolean" }}) as is_high_priority,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(priority as {{ dbt.type_string() }}) as priority,
        cast(record_type_id as {{ dbt.type_string() }}) as record_type_id,
        cast(status as {{ dbt.type_string() }}) as status,
        cast(subject as {{ dbt.type_string() }}) as subject,
        cast(task_subtype as {{ dbt.type_string() }}) as task_subtype,
        cast(type as {{ dbt.type_string() }}) as type,
        cast(what_count as {{ dbt.type_int() }}) as what_count,
        cast(what_id as {{ dbt.type_string() }}) as what_id,
        cast(who_count as {{ dbt.type_int() }}) as who_count,
        cast(who_id as {{ dbt.type_string() }}) as who_id

        {{ fivetran_utils.fill_pass_through_columns('salesforce__task_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)