--To disable this model, set the salesforce__opportunity_line_item_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__opportunity_line_item_enabled', True)) }}

{% set opportunity_line_item_column_list = get_opportunity_line_item_columns() %}
{% set opportunity_line_item_column_payload = normalize_column_payload(var('salesforce__opportunity_line_item_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(opportunity_line_item_column_list, opportunity_line_item_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_line_item_pass_through_columns') }}

    from {{ source('salesforce','opportunity_line_item') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
