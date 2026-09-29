--To disable this model, set the salesforce__order_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__order_enabled', True)) }}

{% set order_column_list = get_order_columns() -%}
{% set order_dict = column_list_to_dict(order_column_list) -%}
{% set order_relation = source('salesforce','order') %}
{% set order_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), order_relation.schema, order_relation.identifier) %}

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
        {{ salesforce.cast_and_alias_column("id", order_dict, alias="order_id") }},
        {{ salesforce.cast_and_alias_column("account_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("activated_by_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("activated_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_city", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_country", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_country_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_postal_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_state", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_state_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("billing_street", order_dict) }},
        {{ salesforce.cast_and_alias_column("contract_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("created_by_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("description", order_dict, alias="order_description") }},
        {{ salesforce.cast_and_alias_column("end_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", order_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", order_dict) }},
        {{ salesforce.cast_and_alias_column("opportunity_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("order_number", order_dict) }},
        {{ salesforce.cast_and_alias_column("original_order_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("pricebook_2_id", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_city", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_country", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_country_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_postal_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_state", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_state_code", order_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_street", order_dict) }},
        {{ salesforce.cast_and_alias_column("status", order_dict) }},
        {{ salesforce.cast_and_alias_column("total_amount", order_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("type", order_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__order_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)