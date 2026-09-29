--To disable this model, set the salesforce__opportunity_line_item_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__opportunity_line_item_enabled', True)) }}

{% set opportunity_line_item_column_list = get_opportunity_line_item_columns() -%}
{% set opportunity_line_item_dict = column_list_to_dict(opportunity_line_item_column_list) -%}
{% set opportunity_line_item_relation = source('salesforce','opportunity_line_item') %}
{% set opportunity_line_item_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), opportunity_line_item_relation.schema, opportunity_line_item_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(opportunity_line_item_column_list, opportunity_line_item_column_payload)
        }}
        
    from {{ opportunity_line_item_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", opportunity_line_item_dict, alias="opportunity_line_item_id") }},
        {{ salesforce.cast_and_alias_column("created_by_id", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("description", opportunity_line_item_dict, alias="opportunity_line_item_description") }},
        {{ salesforce.cast_and_alias_column("discount", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("has_quantity_schedule", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("has_revenue_schedule", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("has_schedule", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("list_price", opportunity_line_item_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("name", opportunity_line_item_dict, alias="opportunity_line_item_name") }},
        {{ salesforce.cast_and_alias_column("opportunity_id", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("pricebook_entry_id", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("product_2_id", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("product_code", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("quantity", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("service_date", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("sort_order", opportunity_line_item_dict) }},
        {{ salesforce.cast_and_alias_column("total_price", opportunity_line_item_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("unit_price", opportunity_line_item_dict, datatype=dbt.type_numeric()) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_line_item_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)