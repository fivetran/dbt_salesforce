with opportunity as (

    select *
    from {{ source('salesforce', 'opportunity') }}

), fields as (

    select 

        opportunity.id as opportunity_id,
        amount,
        probability,
        created_date, 
        is_won,
        is_closed,
        forecast_category,
        stage_name,
        owner_id,
        created_date >= {{ dbt_utils.date_trunc('month', dbt_utils.current_timestamp()) }} as is_created_this_month,
        created_date >= {{ dbt_utils.date_trunc('quarter', dbt_utils.current_timestamp()) }} as is_created_this_quarter,
        {{ dbt_utils.datediff(dbt_utils.current_timestamp(), 'created_date', 'day') }} as days_since_created,
        {{ dbt_utils.datediff('close_date', 'created_date', 'day') }} as days_to_close,
        {{ dbt_utils.date_trunc('month', 'close_date') }} = {{ dbt_utils.date_trunc('month', dbt_utils.current_timestamp()) }} as is_closed_this_month,
        {{ dbt_utils.date_trunc('quarter', 'close_date') }} = {{ dbt_utils.date_trunc('quarter', dbt_utils.current_timestamp()) }} as is_closed_this_quarter

    from opportunity
    where not is_deleted

)

select *
from fields
