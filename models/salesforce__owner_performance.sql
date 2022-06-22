with opportunity_aggregation_by_owner as (
    
    select *
    from {{ ref('salesforce__opportunity_aggregation_by_owner') }}  
), 

user as (

    select *
    from {{ var('user') }}
)

select 
    opportunity_aggregation_by_owner.*,
    user.user_name as owner_name,
    user.city as owner_city,
    user.state as owner_state,
    case 
        when (bookings_amount_closed_this_month + lost_amount_this_month) > 0 
            then bookings_amount_closed_this_month / (bookings_amount_closed_this_month + lost_amount_this_month) * 100
        else 0 
    end as win_percent_this_month,
    case 
        when (bookings_amount_closed_this_quarter + lost_amount_this_quarter) > 0 
            then bookings_amount_closed_this_quarter / (bookings_amount_closed_this_quarter + lost_amount_this_quarter) * 100
        else 0 
    end as win_percent_this_quarter,
    case 
        when (total_bookings_amount + total_lost_amount) > 0 
            then total_bookings_amount / (total_bookings_amount + total_lost_amount) * 100
        else 0 
    end as total_win_percent
from opportunity_aggregation_by_owner
join user 
    on user.user_id = opportunity_aggregation_by_owner.owner_id