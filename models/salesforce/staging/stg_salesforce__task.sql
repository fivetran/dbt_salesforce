--To disable this model, set the salesforce__task_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__task_enabled', True)) }}

{% set task_column_list = get_task_columns() -%}
{% set task_source = source('salesforce','task') %}
{% set task_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), task_source.schema, 'task') %}
{% set task_relation = api.Relation.create(database=task_source.database, schema=task_source.schema, identifier=task_column_payload.get('__identifier__', 'task')) %}

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
        id as task_id,
        account_id,
        activity_date,
        call_disposition,
        call_duration_in_seconds,
        call_object,
        call_type,
        completed_date_time,
        created_by_id,
        created_date,
        description as task_description,
        is_archived,
        is_closed,
        is_deleted,
        is_high_priority,
        last_modified_by_id,
        last_modified_date,
        owner_id,
        priority,
        record_type_id,
        status,
        subject,
        task_subtype,
        type,
        what_count,
        what_id,
        who_count,
        who_id
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__task_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)