--To disable this model, set the salesforce__event_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__event_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('event', get_event_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as event_id,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(activity_date as {{ dbt.type_timestamp() }}) as activity_date,
        cast(activity_date_time as {{ dbt.type_timestamp() }}) as activity_date_time,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as event_description,
        cast(end_date as {{ dbt.type_timestamp() }}) as end_date,
        cast(end_date_time as {{ dbt.type_timestamp() }}) as end_date_time,
        cast(event_subtype as {{ dbt.type_string() }}) as event_subtype,
        cast(group_event_type as {{ dbt.type_string() }}) as group_event_type,
        cast(is_archived as {{ "boolean" }}) as is_archived,
        cast(is_child as {{ "boolean" }}) as is_child,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(is_group_event as {{ "boolean" }}) as is_group_event,
        cast(is_recurrence as {{ "boolean" }}) as is_recurrence,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(location as {{ dbt.type_string() }}) as location,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(start_date_time as {{ dbt.type_timestamp() }}) as start_date_time,
        cast(subject as {{ dbt.type_string() }}) as subject,
        cast(type as {{ dbt.type_string() }}) as type,
        cast(what_count as {{ dbt.type_int() }}) as what_count,
        cast(what_id as {{ dbt.type_string() }}) as what_id,
        cast(who_count as {{ dbt.type_int() }}) as who_count,
        cast(who_id as {{ dbt.type_string() }}) as who_id

        {{ fivetran_utils.fill_pass_through_columns('salesforce__event_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
