--To disable this model, set the salesforce__order_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__order_enabled', True)) }}

{% set order_column_list = get_order_columns() %}
{% set order_column_payload = normalize_column_payload(var('salesforce__order_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(order_column_list, order_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__order_pass_through_columns') }}

    from {{ source('salesforce','order') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
