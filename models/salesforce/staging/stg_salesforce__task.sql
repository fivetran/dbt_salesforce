--To disable this model, set the salesforce__task_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__task_enabled', True)) }}

{% set task_column_list = get_task_columns() %}
{% set task_column_payload = normalize_column_payload(var('salesforce__task_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(task_column_list, task_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__task_pass_through_columns') }}

    from {{ source('salesforce','task') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
