with opportunity as (
    
    select *
    from {{ ref('stg_salesforce_opportunity') }}

), user as (

    select *
    from {{ ref('stg_salesforce_user') }}
  
), add_fields as (

    select 
      opportunity.* ,
      opportunity_owner.manager_id,
      case
        when is_won then 'Won'
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
    join user as opportunity_owner on opportunity.owner_id = opportunity_owner.user_id

)

select *
from add_fields


