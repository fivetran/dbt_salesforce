--To disable this model, set the salesforce__product_2_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__product_2_enabled', True)) }}

{% set product_2_column_list = get_product_2_columns() -%}
{% set product_2_dict = column_list_to_dict(product_2_column_list) -%}
{% set product_2_relation = source('salesforce','product_2') %}
{% set product_2_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), product_2_relation.schema, product_2_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(product_2_column_list, product_2_column_payload)
        }}
        
    from {{ product_2_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", product_2_dict, alias="product_2_id") }},
        {{ salesforce.cast_and_alias_column("created_by_id", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("description", product_2_dict, alias="product_2_description") }},
        {{ salesforce.cast_and_alias_column("display_url", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("external_id", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("family", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("is_active", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("is_archived", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("name", product_2_dict, alias="product_2_name") }},
        {{ salesforce.cast_and_alias_column("number_of_quantity_installments", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_revenue_installments", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("product_code", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("quantity_installment_period", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("quantity_schedule_type", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("quantity_unit_of_measure", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("record_type_id", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("revenue_installment_period", product_2_dict) }},
        {{ salesforce.cast_and_alias_column("revenue_schedule_type", product_2_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__product_2_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)