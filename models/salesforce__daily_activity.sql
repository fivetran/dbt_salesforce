
-- for any given day, see what leads/accounts/opportunities are in the pipeline
with date_spine as (
    select 
        {{ dbt_utils.date_trunc('day', 'date_day') }} as date_day
    
    from {{ ref('salesforce__date_spine') }}

),

task as (
    
    select 
        task_id,
        account_id,
        {{ dbt_utils.date_trunc('day', 'activity_date') }} as activity_date,
        completed_date_time,
        is_closed,
        is_deleted,
        owner_id,
        status,
        type,
        task_subtype
    from  {{ var('task') }}
), 

salesforce_event as (

    select 
        event_id,
        account_id,
        {{ dbt_utils.date_trunc('day', 'activity_date') }} as activity_date,
        created_date,
        event_subtype,
        owner_id,
        type
    from {{ var('event') }}  
), 

salesforce_lead as (

    select 
        lead_id,
        converted_account_id,
        owner_id,
        {{ dbt_utils.date_trunc('day', 'created_date') }} as created_date,
        {{ dbt_utils.date_trunc('day', 'converted_date') }} as converted_date,
        status

    from {{ var('lead') }}
), 

salesforce_converted_lead as (

    select 
        lead_id,
        converted_account_id,
        owner_id,
        {{ dbt_utils.date_trunc('day', 'converted_date') }} as converted_date,
        status
    from {{ var('lead') }}
    where is_converted is true

), 

account as (
    select
        account_id,
        owner_id,
        type
    from {{ var('account') }}
),

opportunity as (

    select 
        opportunity_id,
        {{ dbt_utils.date_trunc('day', 'created_date') }} as created_date,
        account_id,
        {{ dbt_utils.date_trunc('day', 'close_date') }} as close_date,
        is_closed,
        is_deleted,
        is_won,
        owner_id, 
        stage_name,
        type,
        case
            when is_won then 'Won'
            when not is_won and is_closed then 'Lost'
            when not is_closed and lower(forecast_category) in ('pipeline','forecast','bestcase') then 'Pipeline'
            else 'Other'
        end as status
    from {{ var('opportunity') }}
)



select

    date_spine.date_day,
    case
        when opportunity.status = 'Won' then count(distinct opportunity.opportunity_id) 
        else 0 
    end as won_opportunities,
    case
        when opportunity.status = 'Lost' then count(distinct opportunity.opportunity_id) 
        else 0 
    end as lost_opportunities,
    count(distinct task.task_id) as tasks,
    count(distinct salesforce_event.event_id) as events


    from date_spine
    left join opportunity
        on date_spine.date_day = opportunity.close_date
    left join task  
        on date_spine.date_day = task.activity_date
    left join salesforce_event
        on date_spine.date_day = salesforce_event.activity_date

    group by date_day, opportunity.status

