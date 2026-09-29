--To disable this model, set the salesforce__product_2_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__product_2_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('product_2', get_product_2_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as product_2_id,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as product_2_description,
        cast(display_url as {{ dbt.type_string() }}) as display_url,
        cast(external_id as {{ dbt.type_string() }}) as external_id,
        cast(family as {{ dbt.type_string() }}) as family,
        cast(is_active as {{ "boolean" }}) as is_active,
        cast(is_archived as {{ "boolean" }}) as is_archived,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(name as {{ dbt.type_string() }}) as product_2_name,
        cast(number_of_quantity_installments as {{ dbt.type_int() }}) as number_of_quantity_installments,
        cast(number_of_revenue_installments as {{ dbt.type_int() }}) as number_of_revenue_installments,
        cast(product_code as {{ dbt.type_string() }}) as product_code,
        cast(quantity_installment_period as {{ dbt.type_string() }}) as quantity_installment_period,
        cast(quantity_schedule_type as {{ dbt.type_string() }}) as quantity_schedule_type,
        cast(quantity_unit_of_measure as {{ dbt.type_string() }}) as quantity_unit_of_measure,
        cast(record_type_id as {{ dbt.type_string() }}) as record_type_id,
        cast(revenue_installment_period as {{ dbt.type_string() }}) as revenue_installment_period,
        cast(revenue_schedule_type as {{ dbt.type_string() }}) as revenue_schedule_type

        {{ fivetran_utils.fill_pass_through_columns('salesforce__product_2_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)