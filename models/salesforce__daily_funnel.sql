
-- for any given day, see what leads/accounts/opportunities are in the pipeline

with task as (
    
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
        close_date,
        is_closed,
        is_deleted,
        is_won,
        owner_id, 
        stage_name,
        type
    from {{ var('opportunity') }}
)



select


    salesforce_lead.created_date as lead_created_date,
    salesforce_lead.lead_id,
    salesforce_lead.converted_account_id,
    salesforce_lead.converted_date as lead_converted_date,
    opportunity.opportunity_id,
    opportunity.created_date as opportunity_created_date,
    task.task_id,
    task.activity_date as task_activity_date,
    salesforce_event.event_id,
    salesforce_event.activity_date as event_activity_date

    from salesforce_lead
    left join opportunity
        on salesforce_lead.converted_account_id = opportunity.account_id
    left join task 
        on salesforce_lead.converted_account_id = task.account_id
    left join salesforce_event
        on salesforce_lead.converted_account_id = salesforce_event.account_id