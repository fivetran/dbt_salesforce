--To disable this model, set the salesforce__event_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__event_enabled', True)) }}

{% set event_column_list = get_event_columns() -%}
{% set event_dict = column_list_to_dict(event_column_list) -%}
{% set event_relation = source('salesforce','event') %}
{% set event_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), event_relation.schema, event_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(event_column_list, event_column_payload)
        }}

    from {{ event_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", event_dict, alias="event_id") }},
        {{ salesforce.cast_and_alias_column("account_id", event_dict) }},
        {{ salesforce.cast_and_alias_column("activity_date", event_dict) }},
        {{ salesforce.cast_and_alias_column("activity_date_time", event_dict) }},
        {{ salesforce.cast_and_alias_column("created_by_id", event_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", event_dict) }},
        {{ salesforce.cast_and_alias_column("description", event_dict, alias="event_description") }},
        {{ salesforce.cast_and_alias_column("end_date", event_dict) }},
        {{ salesforce.cast_and_alias_column("end_date_time", event_dict) }},
        {{ salesforce.cast_and_alias_column("event_subtype", event_dict) }},
        {{ salesforce.cast_and_alias_column("group_event_type", event_dict) }},
        {{ salesforce.cast_and_alias_column("is_archived", event_dict) }},
        {{ salesforce.cast_and_alias_column("is_child", event_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", event_dict) }},
        {{ salesforce.cast_and_alias_column("is_group_event", event_dict) }},
        {{ salesforce.cast_and_alias_column("is_recurrence", event_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", event_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", event_dict) }},
        {{ salesforce.cast_and_alias_column("location", event_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", event_dict) }},
        {{ salesforce.cast_and_alias_column("start_date_time", event_dict) }},
        {{ salesforce.cast_and_alias_column("subject", event_dict) }},
        {{ salesforce.cast_and_alias_column("type", event_dict) }},
        {{ salesforce.cast_and_alias_column("what_count", event_dict) }},
        {{ salesforce.cast_and_alias_column("what_id", event_dict) }},
        {{ salesforce.cast_and_alias_column("who_count", event_dict) }},
        {{ salesforce.cast_and_alias_column("who_id", event_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__event_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
