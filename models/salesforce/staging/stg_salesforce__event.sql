--To disable this model, set the salesforce__event_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__event_enabled', True)) }}

{% set event_column_list = get_event_columns() %}
{% set event_column_payload = normalize_column_payload(var('salesforce__event_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(event_column_list, event_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__event_pass_through_columns') }}

    from {{ source('salesforce','event') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
