with opportunity_aggregation_by_owner as (
    
    select *
    from {{ ref('opportunity_aggregation_by_owner') }}
  
), user as (

    select *
    from {{ ref('stg_salesforce_user') }}
  
)

select 
  opportunity_aggregation_by_owner.*,
	user.name as owner_name,
  user.city as owner_city,
  user.state as owner_state,
  if((bookings_amount_closed_this_month + lost_amount_this_month) > 0, 
        bookings_amount_closed_this_month / 
          (bookings_amount_closed_this_month + lost_amount_this_month) * 100,
          0) as win_percent_this_month,
  if((bookings_amount_closed_this_quarter + lost_amount_this_quarter) > 0, 
        bookings_amount_closed_this_quarter / 
          (bookings_amount_closed_this_quarter + lost_amount_this_quarter) * 100,
          0) as win_percent_this_quarter,
  if((total_bookings_amount + total_lost_amount) > 0, 
        total_bookings_amount / (total_bookings_amount + total_lost_amount) * 100,
        0) as total_win_percent

from opportunity_aggregation_by_owner
join user on user.user_id = opportunity_aggregation_by_owner.owner_id