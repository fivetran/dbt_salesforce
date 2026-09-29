--To disable this model, set the salesforce__product_2_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__product_2_enabled', True)) }}

{% set product_2_column_list = get_product_2_columns() %}
{% set product_2_column_payload = normalize_column_payload(var('salesforce__product_2_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(product_2_column_list, product_2_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__product_2_pass_through_columns') }}

    from {{ source('salesforce','product_2') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
