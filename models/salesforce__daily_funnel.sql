
-- for any given day, see what leads/accounts/opportunities are in the pipeline

with task as (
    
    select 
        task_id,
        account_id,
        activity_date,
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
        activity_date,
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
        created_date,
        status

    from {{ var('lead') }}
), 

salesforce_converted_lead as (

    select 
        lead_id,
        converted_account_id,
        owner_id,
        converted_date,
        status
    from {{ var('lead') }}
), 

account as (
    select
        account_id,
        last_activity_date,
        owner_id,
        type
    from {{ var('account') }}
),

opportunity as (

    select 
        opportunity_id,
        created_date,
        close_date,
        account_id,
        is_closed,
        is_deleted,
        is_won,
        owner_id, 
        stage_name,
        type
    from {{ var('opportunity') }}
    where is_won is true
)

select
    salesforce_lead.created_date,	
    salesforce_lead.lead_id,
    
    opportunity.opportunity_id,
    opportunity.stage_name
    -- ,
    -- count(distinct salesforce_converted_lead.converted_account_id) as converted_account_count,
    -- count(task.task_id) as task_count,
    -- count(salesforce_event.event_id) as event_count,
    -- count(distinct(case when opportunity.is_won then opportunity.opportunity_id else null end)) as won_opportunity_count 


    from salesforce_lead
    -- left join salesforce_converted_lead
    --     on salesforce_lead.created_date = salesforce_converted_lead.converted_date
    -- left join task 
    --     on salesforce_lead.created_date = task.activity_date
    -- left join salesforce_event
    --     on salesforce_lead.created_date = salesforce_event.activity_date
    left join opportunity
        on salesforce_lead.converted_account_id = opportunity.account_id
        -- on salesforce_lead.created_date = opportunity.close_date -- concern is if this doesn't exactly equal the date the opportunity was won, need to figure that out
