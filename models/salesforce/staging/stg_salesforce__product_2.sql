--To disable this model, set the salesforce__product_2_enabled variable within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__product_2_enabled', True)) }}

{% set product_2_column_list = get_product_2_columns() -%}
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
        id as product_2_id,
        created_by_id,
        created_date,
        description as product_2_description,
        display_url,
        external_id,
        family,
        is_active,
        is_archived,
        is_deleted,
        last_modified_by_id,
        last_modified_date,
        last_referenced_date,
        last_viewed_date,
        name as product_2_name,
        number_of_quantity_installments,
        number_of_revenue_installments,
        product_code,
        quantity_installment_period,
        quantity_schedule_type,
        quantity_unit_of_measure,
        record_type_id,
        revenue_installment_period,
        revenue_schedule_type
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__product_2_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)