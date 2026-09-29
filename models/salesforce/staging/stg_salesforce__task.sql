--To disable this model, set the salesforce__task_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__task_enabled', True)) }}

{% set task_column_list = get_task_columns() -%}
{% set task_dict = column_list_to_dict(task_column_list) -%}
{% set task_relation = source('salesforce','task') %}
{% set task_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), task_relation.schema, task_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(task_column_list, task_column_payload)
        }}
        
    from {{ task_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", task_dict, alias="task_id") }},
        {{ salesforce.cast_and_alias_column("account_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("activity_date", task_dict) }},
        {{ salesforce.cast_and_alias_column("call_disposition", task_dict) }},
        {{ salesforce.cast_and_alias_column("call_duration_in_seconds", task_dict) }},
        {{ salesforce.cast_and_alias_column("call_object", task_dict) }},
        {{ salesforce.cast_and_alias_column("call_type", task_dict) }},
        {{ salesforce.cast_and_alias_column("completed_date_time", task_dict) }},
        {{ salesforce.cast_and_alias_column("created_by_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", task_dict) }},
        {{ salesforce.cast_and_alias_column("description", task_dict, alias="task_description") }},
        {{ salesforce.cast_and_alias_column("is_archived", task_dict) }},
        {{ salesforce.cast_and_alias_column("is_closed", task_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", task_dict) }},
        {{ salesforce.cast_and_alias_column("is_high_priority", task_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", task_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("priority", task_dict) }},
        {{ salesforce.cast_and_alias_column("record_type_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("status", task_dict) }},
        {{ salesforce.cast_and_alias_column("subject", task_dict) }},
        {{ salesforce.cast_and_alias_column("task_subtype", task_dict) }},
        {{ salesforce.cast_and_alias_column("type", task_dict) }},
        {{ salesforce.cast_and_alias_column("what_count", task_dict) }},
        {{ salesforce.cast_and_alias_column("what_id", task_dict) }},
        {{ salesforce.cast_and_alias_column("who_count", task_dict) }},
        {{ salesforce.cast_and_alias_column("who_id", task_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__task_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)