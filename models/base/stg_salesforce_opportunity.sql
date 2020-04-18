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
        owner_id,
        date(created_date) >= date_trunc(current_date(), month) as is_created_this_month,
        date(created_date) >= date_trunc(current_date(), quarter) as is_created_this_quarter,
        date_diff(current_date(), date(opportunity.created_date), day) as days_since_created,
        date_diff(date(opportunity.close_date), date(opportunity.created_date), day) as days_to_close,
        date(close_date) >= date_trunc(current_date(), month) as is_closed_this_month,
        date(close_date) >= date_trunc(current_date(), quarter) as is_closed_this_quarter,

    from opportunity
    where not is_deleted

)

select *
from fields