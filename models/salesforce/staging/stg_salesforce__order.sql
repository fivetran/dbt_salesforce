--To disable this model, set the salesforce__order_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__order_enabled', True)) }}

{% set order_column_list = get_order_columns() -%}
{% set order_source = source('salesforce','order') %}
{% set order_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), order_source.schema, 'order') %}
{% set order_relation = api.Relation.create(database=order_source.database, schema=order_source.schema, identifier=order_column_payload.get('__identifier__', 'order')) %}

with fields as (

    select
        {{
            apply_column_payload(order_column_list, order_column_payload)
        }}
        
    from {{ order_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        id as order_id,
        account_id,
        activated_by_id,
        activated_date,
        billing_city,
        billing_country,
        billing_country_code,
        billing_postal_code,
        billing_state,
        billing_state_code,
        billing_street,
        contract_id,
        created_by_id,
        created_date,
        description as order_description,
        end_date,
        is_deleted,
        last_modified_by_id,
        last_modified_date,
        last_referenced_date,
        last_viewed_date,
        opportunity_id,
        order_number,
        original_order_id,
        owner_id,
        pricebook_2_id,
        shipping_city,
        shipping_country,
        shipping_country_code,
        shipping_postal_code,
        shipping_state,
        shipping_state_code,
        shipping_street,
        status,
        cast(total_amount as {{ dbt.type_numeric() }}) as total_amount,
        type
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__order_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)