--To disable this model, set the salesforce__opportunity_line_item_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__opportunity_line_item_enabled', True)) }}

{% set opportunity_line_item_column_list = get_opportunity_line_item_columns() -%}
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
        id as opportunity_line_item_id,
        created_by_id,
        created_date,
        description as opportunity_line_item_description,
        discount,
        has_quantity_schedule,
        has_revenue_schedule,
        has_schedule,
        is_deleted,
        last_modified_by_id,
        last_modified_date,
        last_referenced_date,
        last_viewed_date,
        cast(list_price as {{ dbt.type_numeric() }}) as list_price,
        name as opportunity_line_item_name,
        opportunity_id,
        pricebook_entry_id,
        product_2_id,
        product_code,
        quantity,
        service_date,
        sort_order,
        cast(total_price as {{ dbt.type_numeric() }}) as total_price,
        cast(unit_price as {{ dbt.type_numeric() }}) as unit_price
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_line_item_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)