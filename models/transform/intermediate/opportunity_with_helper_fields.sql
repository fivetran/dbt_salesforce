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
      if(is_created_this_month, amount, 0) as created_amount_this_month,
      if(is_created_this_quarter, amount, 0) as created_amount_this_quarter,
      if(is_created_this_month, 1, 0) as created_count_this_month,
      if(is_created_this_quarter, 1, 0) as created_count_this_quarter,
      if(is_closed_this_month, amount, 0) as closed_amount_this_month,
      if(is_closed_this_quarter, amount, 0) as closed_amount_this_quarter,
      if(is_closed_this_month, 1, 0) as closed_count_this_month,
      if(is_closed_this_quarter, 1, 0) as closed_count_this_quarter,
      
    from opportunity
    join user as opportunity_owner on opportunity.owner_id = opportunity_owner.user_id

)

select *
from add_fields


