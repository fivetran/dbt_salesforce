with date_spine as (
    
    select 
        {{ dbt_utils.date_trunc('day', 'date_day') }} as date_day
    from {{ ref('salesforce__date_spine') }}
),

task as (
    
    select 
        {{ dbt_utils.date_trunc('day', 'activity_date') }} as activity_date,
        count(task_id) as tasks
    from {{ var('task') }}
    group by 1
), 

salesforce_event as (

    select 
        {{ dbt_utils.date_trunc('day', 'activity_date') }} as activity_date,
        count(event_id) as events
    from {{ var('event') }}  
    group by 1
), 

salesforce_lead as (

    select 
        {{ dbt_utils.date_trunc('day', 'created_date') }} as created_date,
        count(lead_id) as leads_created
    from {{ var('lead') }}
    group by 1
), 

salesforce_converted_lead as (

    select 
        {{ dbt_utils.date_trunc('day', 'converted_date') }} as converted_date,
        count(lead_id) as leads_converted
    from {{ var('lead') }}
    where is_converted
    group by 1
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
),

opportunities_created as (

    select
        created_date,
        count(opportunity_id) as opportunities_created
    from opportunity
    group by 1
),

opportunities_closed as (

    select
        close_date,
        count(case when status = 'Won' then opportunity_id else null end) as won_opportunities,
        count(case when status = 'Lost' then opportunity_id else null end) as lost_opportunities
    from opportunity
    group by 1
)

select
    date_spine.date_day,
    salesforce_lead.leads_created,
    salesforce_converted_lead.leads_converted,
    task.tasks,
    salesforce_event.events,
    opportunities_created.opportunities_created,
    opportunities_closed.won_opportunities,
    opportunities_closed.lost_opportunities
from date_spine
left join salesforce_lead
    on date_spine.date_day = salesforce_lead.created_date
left join salesforce_converted_lead
    on date_spine.date_day = salesforce_converted_lead.converted_date
left join task
    on date_spine.date_day = task.activity_date
left join salesforce_event
    on date_spine.date_day = salesforce_event.activity_date
left join opportunities_created
    on date_spine.date_day = opportunities_created.created_date
left join opportunities_closed
    on date_spine.date_day = opportunities_closed.close_date
