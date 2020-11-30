with opportunity_aggregation_by_owner as (
    
    select *
    from {{ ref('salesforce__opportunity_aggregation_by_owner') }}
  
), salesforce_user as (

    select *
    from {{ var('user') }}
  
), user_role as (

    select *
    from {{ var('user_role') }}
  
)

select 
  coalesce(manager.user_id, 'No Manager Assigned') as manager_id,  
  coalesce(manager.user_name, 'No Manager Assigned') as manager_name,
  manager.city as manager_city,
  manager.state as manager_state,
  user_role.user_role_name as manager_position,
  count(distinct owner_id) as number_of_direct_reports,
  coalesce(sum(bookings_amount_closed_this_month), 0) as bookings_amount_closed_this_month,
  coalesce(sum(bookings_amount_closed_this_quarter), 0) as bookings_amount_closed_this_quarter,
  coalesce(sum(total_number_bookings), 0) as total_number_bookings,
  coalesce(sum(total_bookings_amount), 0) as total_bookings_amount,
  coalesce(sum(bookings_count_closed_this_month), 0) as bookings_count_closed_this_month,
  coalesce(sum(bookings_count_closed_this_quarter), 0) as bookings_count_closed_this_quarter,
  coalesce(max(largest_booking), 0) as largest_booking,
  coalesce(sum(lost_amount_this_month), 0) as lost_amount_this_month,
  coalesce(sum(lost_amount_this_quarter), 0) as lost_amount_this_quarter,
  coalesce(sum(total_number_lost), 0) as total_number_lost,
  coalesce(sum(total_lost_amount), 0) as total_lost_amount,
  coalesce(sum(lost_count_this_month), 0) as lost_count_this_month,
  coalesce(sum(lost_count_this_quarter), 0) as lost_count_this_quarter,
  coalesce(sum(pipeline_created_amount_this_month), 0) as pipeline_created_amount_this_month,
  coalesce(sum(pipeline_created_amount_this_quarter), 0) as pipeline_created_amount_this_quarter,
  coalesce(sum(pipeline_created_forecast_amount_this_month), 0) as pipeline_created_forecast_amount_this_month,
  coalesce(sum(pipeline_created_forecast_amount_this_quarter), 0) as pipeline_created_forecast_amount_this_quarter,
  coalesce(sum(pipeline_count_created_this_month), 0) as pipeline_count_created_this_month,
  coalesce(sum(pipeline_count_created_this_quarter), 0) as pipeline_count_created_this_quarter,
  coalesce(sum(total_number_pipeline), 0) as total_number_pipeline,
  coalesce(sum(total_pipeline_amount), 0) as total_pipeline_amount,
  coalesce(sum(total_pipeline_forecast_amount), 0) as total_pipeline_forecast_amount,
  coalesce(max(largest_deal_in_pipeline), 0) as largest_deal_in_pipeline,
  round(case when sum(bookings_amount_closed_this_month + lost_amount_this_month) > 0 then 
            sum(bookings_amount_closed_this_month) / sum(bookings_amount_closed_this_month + lost_amount_this_month) * 100
            else 0 end, 2) as win_percent_this_month,
  round(case when sum(bookings_amount_closed_this_quarter + lost_amount_this_quarter) > 0 then
            sum(bookings_amount_closed_this_quarter) / sum(bookings_amount_closed_this_quarter + lost_amount_this_quarter) * 100
            else 0 end, 2) as win_percent_this_quarter,
  round(case when sum(total_bookings_amount + total_lost_amount) > 0 then 
            sum(total_bookings_amount) / sum(total_bookings_amount + total_lost_amount) * 100
            else 0 end, 2) as total_win_percent

from opportunity_aggregation_by_owner

left join salesforce_user as manager 
  on manager.user_id = opportunity_aggregation_by_owner.manager_id
left join user_role 
  on user_role.user_role_id = manager.user_role_id

group by 1, 2, 3, 4, 5

having count(distinct owner_id) > 0