with task as (
    
    select *
    from {{ var('task') }}
), 

salesforce_event as (

    select *
    from {{ var('event') }}  
), 

salesforce_lead as (

    select *
    from {{ var('lead') }}
), 

salesforce_converted_lead as (

    select *
    from {{ var('lead') }}
), 

opportunity as (

    select *
    from {{ var('opportunity') }}
)

select
    salesforce_lead.created_date,	
    count(salesforce_lead.lead_id) as lead_count,
    count(distinct salesforce_converted_lead.converted_account_id) as converted_account_count,
    count(task.task_id) as task_count,
    count(salesforce_event.event_id) as event_count,
    count(distinct(case when opportunity.is_won then opportunity.opportunity_id else null end)) as won_opportunity_count 


    from salesforce_lead
    left join salesforce_converted_lead
        on salesforce_lead.created_date = salesforce_converted_lead.converted_date
    left join task 
        on salesforce_lead.created_date = task.activity_date
    left join salesforce_event
        on salesforce_lead.created_date = salesforce_event.activity_date
    left join opportunity
        on salesforce_lead.created_date = opportunity.last_activity_date -- concern is if this doesn't exactly equal the date the opportunity was won, need to figure that out

    group by created_date