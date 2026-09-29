with fields as (

    {{ salesforce.select_payload_fields('account', get_account_columns()) }}
), 

final as (
    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(account_number as {{ dbt.type_string() }}) as account_number,
        cast(account_source as {{ dbt.type_string() }}) as account_source,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        cast(billing_city as {{ dbt.type_string() }}) as billing_city,
        cast(billing_country as {{ dbt.type_string() }}) as billing_country,
        cast(billing_postal_code as {{ dbt.type_string() }}) as billing_postal_code,
        cast(billing_state as {{ dbt.type_string() }}) as billing_state,
        cast(billing_state_code as {{ dbt.type_string() }}) as billing_state_code,
        cast(billing_street as {{ dbt.type_string() }}) as billing_street,
        cast(description as {{ dbt.type_string() }}) as account_description,
        cast(id as {{ dbt.type_string() }}) as account_id,
        cast(industry as {{ dbt.type_string() }}) as industry,
        cast(is_deleted as {{ dbt.type_boolean() }}) as is_deleted,
        cast(last_activity_date as {{ dbt.type_timestamp() }}) as last_activity_date,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(master_record_id as {{ dbt.type_string() }}) as master_record_id,
        cast(name as {{ dbt.type_string() }}) as account_name,
        cast(number_of_employees as {{ dbt.type_int() }}) as number_of_employees,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(ownership as {{ dbt.type_string() }}) as ownership,
        cast(parent_id as {{ dbt.type_string() }}) as parent_id,
        cast(rating as {{ dbt.type_string() }}) as rating,
        cast(record_type_id as {{ dbt.type_string() }}) as record_type_id,
        cast(shipping_city as {{ dbt.type_string() }}) as shipping_city,
        cast(shipping_country as {{ dbt.type_string() }}) as shipping_country,
        cast(shipping_country_code as {{ dbt.type_string() }}) as shipping_country_code,
        cast(shipping_postal_code as {{ dbt.type_string() }}) as shipping_postal_code,
        cast(shipping_state as {{ dbt.type_string() }}) as shipping_state,
        cast(shipping_state_code as {{ dbt.type_string() }}) as shipping_state_code,
        cast(shipping_street as {{ dbt.type_string() }}) as shipping_street,
        cast(type as {{ dbt.type_string() }}) as type,
        cast(website as {{ dbt.type_string() }}) as website

        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)