--To disable this model, set the salesforce__opportunity_line_item_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__opportunity_line_item_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('opportunity_line_item', get_opportunity_line_item_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as opportunity_line_item_id,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as opportunity_line_item_description,
        cast(discount as {{ dbt.type_float() }}) as discount,
        cast(has_quantity_schedule as {{ "boolean" }}) as has_quantity_schedule,
        cast(has_revenue_schedule as {{ "boolean" }}) as has_revenue_schedule,
        cast(has_schedule as {{ "boolean" }}) as has_schedule,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(list_price as {{ dbt.type_numeric() }}) as list_price,
        cast(name as {{ dbt.type_string() }}) as opportunity_line_item_name,
        cast(opportunity_id as {{ dbt.type_string() }}) as opportunity_id,
        cast(pricebook_entry_id as {{ dbt.type_string() }}) as pricebook_entry_id,
        cast(product_2_id as {{ dbt.type_string() }}) as product_2_id,
        cast(product_code as {{ dbt.type_string() }}) as product_code,
        cast(quantity as {{ dbt.type_float() }}) as quantity,
        cast(service_date as {{ dbt.type_timestamp() }}) as service_date,
        cast(sort_order as {{ dbt.type_int() }}) as sort_order,
        cast(total_price as {{ dbt.type_numeric() }}) as total_price,
        cast(unit_price as {{ dbt.type_numeric() }}) as unit_price

        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_line_item_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)