



with __dbt__CTE__stg_salesforce_opportunity as (
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
)select count(*)
from __dbt__CTE__stg_salesforce_opportunity
where opportunity_id is null

