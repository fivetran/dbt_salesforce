with opportunity as (
    
    select *
    from {{ var('opportunity') }}
), 

salesforce_user as (

    select *
    from {{ var('user') }}  
), 

account as (

    select *
    from {{ var('account') }}
), 

add_fields as (

    select 
        opportunity.*,
        account.account_number,
        account.account_source,
        account.industry,
        account.account_name,
        account.number_of_employees,
        account.type as account_type,
        opportunity_owner.user_id as opportunity_owner_id,
        opportunity_owner.user_name as opportunity_owner_name,
        opportunity_owner.city opportunity_owner_city,
        opportunity_owner.state as opportunity_owner_state,
        opportunity_manager.user_id as opportunity_manager_id,
        opportunity_manager.user_name as opportunity_manager_name,
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

        --The below script allows for pass through columns.

        {% if var('opportunity_enhanced_pass_through_columns',[]) != [] %}
        , {{ var('opportunity_enhanced_pass_through_columns') | join (", ")}}

        {% endif %}

    from opportunity
    left join account 
        on opportunity.account_id = account.account_id
    left join salesforce_user as opportunity_owner 
        on opportunity.owner_id = opportunity_owner.user_id
    left join salesforce_user as opportunity_manager 
        on opportunity_owner.manager_id = opportunity_manager.user_id
)

select *
from add_fields
