{% set account_column_list = get_account_columns() -%}
{% set account_relation = source('salesforce','account') %}
{% set account_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), account_relation.schema, account_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(account_column_list, account_column_payload)
        }}

    from {{ account_relation }}
), 

final as (
    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        account_number,
        account_source,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        billing_city,
        billing_country,
        billing_postal_code,
        billing_state,
        billing_state_code,
        billing_street,
        description as account_description,
        id as account_id,
        industry,
        is_deleted,
        last_activity_date,
        last_referenced_date,
        last_viewed_date,
        master_record_id,
        name as account_name,
        number_of_employees,
        owner_id,
        ownership,
        parent_id,
        rating,
        record_type_id,
        shipping_city,
        shipping_country,
        shipping_country_code,
        shipping_postal_code,
        shipping_state,
        shipping_state_code,
        shipping_street,
        type,
        website

        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)