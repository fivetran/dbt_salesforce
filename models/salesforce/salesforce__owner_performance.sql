with opportunity_aggregation_by_owner as (
    
    select *
    from {{ ref('int_salesforce__opportunity_aggregation_by_owner') }}  
), 

salesforce_user as (

    select *
    from {{ ref('stg_salesforce__user') }}
)

select 
    opportunity_aggregation_by_owner.*,
    salesforce_user.user_name as owner_name,
    salesforce_user.city as owner_city,
    salesforce_user.state as owner_state,
    case 
        when (coalesce(bookings_amount_closed_this_month, 0) + coalesce(lost_amount_this_month, 0)) > 0 
            then coalesce(bookings_amount_closed_this_month, 0) / (coalesce(bookings_amount_closed_this_month, 0) + coalesce(lost_amount_this_month, 0)) * 100
        else 0 
    end as win_percent_this_month,
    case 
        when (coalesce(bookings_amount_closed_this_quarter, 0) + coalesce(lost_amount_this_quarter, 0)) > 0 
            then coalesce(bookings_amount_closed_this_quarter, 0) / (coalesce(bookings_amount_closed_this_quarter, 0) + coalesce(lost_amount_this_quarter, 0)) * 100
        else 0 
    end as win_percent_this_quarter,
    case 
        when (coalesce(total_bookings_amount, 0) + coalesce(total_lost_amount, 0)) > 0 
            then coalesce(total_bookings_amount, 0) / (coalesce(total_bookings_amount, 0) + coalesce(total_lost_amount, 0)) * 100
        else 0 
    end as total_win_percent
from opportunity_aggregation_by_owner
join salesforce_user 
    on salesforce_user.user_id = opportunity_aggregation_by_owner.owner_id