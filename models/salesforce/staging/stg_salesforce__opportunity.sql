with fields as (

    {{ salesforce.select_payload_fields('opportunity', get_opportunity_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(amount as {{ dbt.type_numeric() }}) as amount,
        cast(campaign_id as {{ dbt.type_string() }}) as campaign_id,
        cast(close_date as {{ dbt.type_timestamp() }}) as close_date,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as opportunity_description,
        cast(expected_revenue as {{ dbt.type_numeric() }}) as expected_revenue,
        cast(fiscal as {{ dbt.type_string() }}) as fiscal,
        cast(fiscal_quarter as {{ dbt.type_int() }}) as fiscal_quarter,
        cast(fiscal_year as {{ dbt.type_int() }}) as fiscal_year,
        cast(forecast_category as {{ dbt.type_string() }}) as forecast_category,
        cast(forecast_category_name as {{ dbt.type_string() }}) as forecast_category_name,
        cast(has_open_activity as {{ "boolean" }}) as has_open_activity,
        cast(has_opportunity_line_item as {{ "boolean" }}) as has_opportunity_line_item,
        cast(has_overdue_task as {{ "boolean" }}) as has_overdue_task,
        cast(id as {{ dbt.type_string() }}) as opportunity_id,
        cast(is_closed as {{ "boolean" }}) as is_closed,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(is_won as {{ "boolean" }}) as is_won,
        cast(last_activity_date as {{ dbt.type_timestamp() }}) as last_activity_date,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(lead_source as {{ dbt.type_string() }}) as lead_source,
        cast(name as {{ dbt.type_string() }}) as opportunity_name,
        cast(next_step as {{ dbt.type_string() }}) as next_step,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(probability as {{ dbt.type_float() }}) as probability,
        cast(record_type_id as {{ dbt.type_string() }}) as record_type_id,
        cast(stage_name as {{ dbt.type_string() }}) as stage_name,
        cast(synced_quote_id as {{ dbt.type_string() }}) as synced_quote_id,
        cast(type as {{ dbt.type_string() }}) as type

        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
), 

calculated as (
        
    select 
        *,
        created_date >= {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_created_this_month,
        created_date >= {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_created_this_quarter,
        {{ dbt.datediff(dbt.current_timestamp_backcompat(), 'created_date', 'day') }} as days_since_created,
        {{ dbt.datediff('close_date', 'created_date', 'day') }} as days_to_close,
        {{ dbt.date_trunc('month', 'close_date') }} = {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_closed_this_month,
        {{ dbt.date_trunc('quarter', 'close_date') }} = {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_closed_this_quarter
    from final
)

select * 
from calculated
where not coalesce(is_deleted, false)