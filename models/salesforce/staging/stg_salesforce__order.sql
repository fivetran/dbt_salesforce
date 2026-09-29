--To disable this model, set the salesforce__order_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__order_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('order', get_order_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as order_id,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(activated_by_id as {{ dbt.type_string() }}) as activated_by_id,
        cast(activated_date as {{ dbt.type_timestamp() }}) as activated_date,
        cast(billing_city as {{ dbt.type_string() }}) as billing_city,
        cast(billing_country as {{ dbt.type_string() }}) as billing_country,
        cast(billing_country_code as {{ dbt.type_string() }}) as billing_country_code,
        cast(billing_postal_code as {{ dbt.type_string() }}) as billing_postal_code,
        cast(billing_state as {{ dbt.type_string() }}) as billing_state,
        cast(billing_state_code as {{ dbt.type_string() }}) as billing_state_code,
        cast(billing_street as {{ dbt.type_string() }}) as billing_street,
        cast(contract_id as {{ dbt.type_string() }}) as contract_id,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as order_description,
        cast(end_date as {{ dbt.type_timestamp() }}) as end_date,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(opportunity_id as {{ dbt.type_string() }}) as opportunity_id,
        cast(order_number as {{ dbt.type_string() }}) as order_number,
        cast(original_order_id as {{ dbt.type_string() }}) as original_order_id,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(pricebook_2_id as {{ dbt.type_string() }}) as pricebook_2_id,
        cast(shipping_city as {{ dbt.type_string() }}) as shipping_city,
        cast(shipping_country as {{ dbt.type_string() }}) as shipping_country,
        cast(shipping_country_code as {{ dbt.type_string() }}) as shipping_country_code,
        cast(shipping_postal_code as {{ dbt.type_string() }}) as shipping_postal_code,
        cast(shipping_state as {{ dbt.type_string() }}) as shipping_state,
        cast(shipping_state_code as {{ dbt.type_string() }}) as shipping_state_code,
        cast(shipping_street as {{ dbt.type_string() }}) as shipping_street,
        cast(status as {{ dbt.type_string() }}) as status,
        cast(total_amount as {{ dbt.type_numeric() }}) as total_amount,
        cast(type as {{ dbt.type_string() }}) as type

        {{ fivetran_utils.fill_pass_through_columns('salesforce__order_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)