{% set opportunity_column_list = get_opportunity_columns() -%}
{% set opportunity_relation = source('salesforce','opportunity') %}
{% set opportunity_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), opportunity_relation.schema, opportunity_relation.identifier) %}

with fields as (

    select

        {{
            apply_column_payload(opportunity_column_list, opportunity_column_payload)
        }}

    from {{ opportunity_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        account_id,
        cast(amount as {{ dbt.type_numeric() }}) as amount,
        campaign_id,
        close_date,
        created_date,
        description as opportunity_description,
        expected_revenue,
        fiscal,
        fiscal_quarter,
        fiscal_year,
        forecast_category,
        forecast_category_name,
        has_open_activity,
        has_opportunity_line_item,
        has_overdue_task,
        id as opportunity_id,
        is_closed,
        is_deleted,
        is_won,
        last_activity_date,
        last_referenced_date,
        last_viewed_date,
        lead_source,
        name as opportunity_name,
        next_step,
        owner_id,
        probability,
        record_type_id,
        stage_name,
        synced_quote_id,
        type
        
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