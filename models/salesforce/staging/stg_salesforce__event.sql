--To disable this model, set the salesforce__event_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__event_enabled', True)) }}

{% set event_column_list = get_event_columns() -%}
{% set event_source = source('salesforce','event') %}
{% set event_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), event_source.schema, 'event') %}
{% set event_relation = api.Relation.create(database=event_source.database, schema=event_source.schema, identifier=event_column_payload.get('__identifier__', 'event')) %}

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
        id as event_id,
        account_id,
        activity_date,
        activity_date_time,
        created_by_id,
        created_date,
        description as event_description,
        end_date,
        end_date_time,
        event_subtype,
        group_event_type,
        is_archived,
        is_child,
        is_deleted,
        is_group_event,
        is_recurrence,
        last_modified_by_id,
        last_modified_date,
        location,
        owner_id,
        start_date_time,
        subject,
        type,
        what_count,
        what_id,
        who_count,
        who_id
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__event_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
