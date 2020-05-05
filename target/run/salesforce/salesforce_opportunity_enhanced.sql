

  create or replace table `digital-arbor-400`.`dbt_kristin_test`.`salesforce_opportunity_enhanced`
  
  
  OPTIONS()
  as (
    with  __dbt__CTE__stg_salesforce_opportunity as (
with base as (

    select *
    from salesforce.opportunity
    where not is_deleted

), fields as (

    select 

        id as opportunity_id,
        account_id as opportunity_account_id,
        amount,
        probability,
        created_date, 
        is_won,
        is_closed,
        forecast_category,
        stage_name,
        owner_id,
        close_date,
        created_date >= 
    timestamp_trunc(
        cast(
    current_timestamp
 as timestamp),
        month
    )

 as is_created_this_month,
        created_date >= 
    timestamp_trunc(
        cast(
    current_timestamp
 as timestamp),
        quarter
    )

 as is_created_this_quarter,
        
  

    datetime_diff(
        cast(created_date as datetime),
        cast(
    current_timestamp
 as datetime),
        day
    )


 as days_since_created,
        
  

    datetime_diff(
        cast(created_date as datetime),
        cast(close_date as datetime),
        day
    )


 as days_to_close,
        
    timestamp_trunc(
        cast(close_date as timestamp),
        month
    )

 = 
    timestamp_trunc(
        cast(
    current_timestamp
 as timestamp),
        month
    )

 as is_closed_this_month,
        
    timestamp_trunc(
        cast(close_date as timestamp),
        quarter
    )

 = 
    timestamp_trunc(
        cast(
    current_timestamp
 as timestamp),
        quarter
    )

 as is_closed_this_quarter

    from base

)

select *
from fields
),  __dbt__CTE__stg_salesforce_user as (
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
),  __dbt__CTE__stg_salesforce_account as (
with base as (

    select *
    from salesforce.account
    where not is_deleted

), fields as (

    select 

      id as account_id,
      name as account_name,
      industry,
      number_of_employees,
      account_source,
      rating as account_rating,
      annual_revenue

    from base

)

select *
from fields
),opportunity as (
    
    select *
    from __dbt__CTE__stg_salesforce_opportunity

), user as (

    select *
    from __dbt__CTE__stg_salesforce_user
  
), account as (

    select *
    from __dbt__CTE__stg_salesforce_account
  
), add_fields as (

    select 
      opportunity.* ,
      account.*,
      opportunity_owner.user_id as opportunity_owner_id,
      opportunity_owner.name as opportunity_owner_name,
      opportunity_owner.city opportunity_owner_city,
      opportunity_owner.state as opportunity_owner_state,
      opportunity_manager.user_id as opportunity_manager_id,
      opportunity_manager.name as opportunity_manager_name,
      opportunity_manager.city opportunity_manager_city,
      opportunity_manager.state as opportunity_manager_state,
      case
        when opportunity.is_won then 'Won'
        when not opportunity.is_won and opportunity.is_closed then 'Lost'
        when not opportunity.is_closed and lower(opportunity.forecast_category) in ('pipeline','forecast','bestcase') then 'Pipeline'
        else 'Other'
      end as status,
      case when is_created_this_month then amount else 0 end as created_amount_this_month,
      case when is_created_this_quarter then amount else 0 end as created_amount_this_quarter,
      case when is_created_this_month then 1 else 0 end as created_count_this_month,
      case when is_created_this_quarter then 1 else 0 end as created_count_this_quarter,
      case when is_closed_this_month then amount else 0 end as closed_amount_this_month,
      case when is_closed_this_quarter then amount else 0 end as closed_amount_this_quarter,
      case when is_closed_this_month then 1 else 0 end as closed_count_this_month,
      case when is_closed_this_quarter then 1 else 0 end as closed_count_this_quarter
      
    from opportunity
    left join account on opportunity.opportunity_account_id = account.account_id
    left join user as opportunity_owner on opportunity.owner_id = opportunity_owner.user_id
    left join user as opportunity_manager on opportunity_owner.manager_id = opportunity_manager.user_id
)

select *
from add_fields
  );
    