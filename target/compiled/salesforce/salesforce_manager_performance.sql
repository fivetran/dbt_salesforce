with  __dbt__CTE__stg_salesforce_user as (
with base as (

    select *
    from salesforce.user

), fields as (

    select 
      id as user_id,
      name,
      city,
      state,
      manager_id,
      user_role_id
    from base

)

select *
from fields
),  __dbt__CTE__opportunity_aggregation_by_owner as (
with salesforce_opportunity_enhanced as (
    
    select *
    from `digital-arbor-400`.`dbt_kristin_test`.`salesforce_opportunity_enhanced`
  
), user as (

    select *
    from __dbt__CTE__stg_salesforce_user
  
), booking_by_owner as (

  select 
    opportunity_manager_id as b_manager_id,
    opportunity_owner_id as b_owner_id,
    round(sum(closed_amount_this_month)) as bookings_amount_closed_this_month,
    round(sum(closed_amount_this_quarter)) as bookings_amount_closed_this_quarter,
    count(*) as total_number_bookings,
    round(sum(amount)) as total_bookings_amount,
    sum(closed_count_this_month) as bookings_count_closed_this_month,
    sum(closed_count_this_quarter) as bookings_count_closed_this_quarter,
    round(avg(amount)) as avg_bookings_amount,
    max(amount) as largest_booking,
    avg(days_to_close) as avg_days_to_close
  from salesforce_opportunity_enhanced
  where status = 'Won'
  group by 1, 2

), lost_by_owner as (

  select 
    opportunity_manager_id as l_manager_id,
    opportunity_owner_id as l_owner_id,
    round(sum(closed_amount_this_month)) as lost_amount_this_month,
    round(sum(closed_amount_this_quarter)) as lost_amount_this_quarter,
    count(*) as total_number_lost,
    round(sum(amount)) as total_lost_amount,
    sum(closed_count_this_month) as lost_count_this_month,
    sum(closed_count_this_quarter) as lost_count_this_quarter
  from salesforce_opportunity_enhanced
  where status = 'Lost'
  group by 1, 2

), pipeline_by_owner as (

  select 
    opportunity_manager_id as p_manager_id,
    opportunity_owner_id as p_owner_id,
    round(sum(created_amount_this_month)) as pipeline_created_amount_this_month,
    round(sum(created_amount_this_quarter)) as pipeline_created_amount_this_quarter,
    round(sum(created_amount_this_month * probability)) as pipeline_created_forecast_amount_this_month,
    round(sum(created_amount_this_quarter * probability)) as pipeline_created_forecast_amount_this_quarter,
    sum(created_count_this_month) as pipeline_count_created_this_month,
    sum(created_count_this_quarter) as pipeline_count_created_this_quarter,
    count(*) as total_number_pipeline,
    round(sum(amount)) as total_pipeline_amount,
    round(sum(amount * probability)) as total_pipeline_forecast_amount,
    round(avg(amount)) as avg_pipeline_opp_amount,
    max(amount) as largest_deal_in_pipeline,
    avg(days_since_created) as avg_days_open
  from salesforce_opportunity_enhanced
  where status = 'Pipeline'
  group by 1, 2
)

select 
  user.user_id as owner_id,
  coalesce(p_manager_id, b_manager_id, l_manager_id) as manager_id,
  booking_by_owner.*,
  lost_by_owner.*,
  pipeline_by_owner.*
from user 
left join booking_by_owner on booking_by_owner.b_owner_id = user.user_id
left join lost_by_owner on lost_by_owner.l_owner_id = user.user_id
left join pipeline_by_owner on pipeline_by_owner.p_owner_id = user.user_id
),  __dbt__CTE__stg_salesforce_user_role as (
with base as (

    select *
    from salesforce.user_role
    where not _fivetran_deleted

), fields as (

    select 

      id as user_role_id,
      name as role_name

    from base

)

select *
from fields
),opportunity_aggregation_by_owner as (
    
    select *
    from __dbt__CTE__opportunity_aggregation_by_owner
  
), user as (

    select *
    from __dbt__CTE__stg_salesforce_user
  
), user_role as (

    select *
    from __dbt__CTE__stg_salesforce_user_role
  
)

select 

  coalesce(manager.name, 'No Manager Assigned') as manager_name,
  manager.city as manager_city,
  manager.state as manager_state,
  user_role.role_name as manager_position,
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
left join user as manager on manager.user_id = opportunity_aggregation_by_owner.manager_id
left join user_role on user_role.user_role_id = manager.user_role_id
group by 1, 2, 3, 4
having number_of_direct_reports > 0