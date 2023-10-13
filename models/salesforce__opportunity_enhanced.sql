with opportunity as (
    
    {% if var('not_using_salesforce_history_mode', True) %}
    select *
    from {{ var('opportunity') }}
    {% else %}
    select *,
        created_date >= {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_created_this_month,
        created_date >= {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_created_this_quarter,
        {{ dbt.datediff(dbt.current_timestamp_backcompat(), 'created_date', 'day') }} as days_since_created,
        {{ dbt.datediff('close_date', 'created_date', 'day') }} as days_to_close,
        {{ dbt.date_trunc('month', 'close_date') }} = {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_closed_this_month,
        {{ dbt.date_trunc('quarter', 'close_date') }} = {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_closed_this_quarter
    from {{ var('opportunity_history') }}
    where _fivetran_active = true
    {% endif %}
),

salesforce_user as (

    select *
    {% if var('not_using_salesforce_history_mode', True) %}
    from {{ var('user') }}
    {% else %}
    from {{ var('user_history') }}
    where _fivetran_active = true
    {% endif %}
), 

-- If using user_role table, the following will be included, otherwise it will not.
{% if var('salesforce__user_role_enabled', True) or var('salesforce__user_role_history_enabled', True) %}
user_role as (

    select *
    {% if var('not_using_salesforce_history_mode', True) %}
    from {{ var('user_role') }}
    {% else %}
    from {{ var('user_role_history') }}
    where _fivetran_active = true
    {% endif %}
), 
{% endif %}

account as (

    select *
    {% if var('not_using_salesforce_history_mode', True) %}
    from {{ var('account') }}
    {% else %}
    from {{ var('account_history') }}
    where _fivetran_active = true
    {% endif %} 
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
        opportunity_owner.user_role_id as opportunity_owner_role_id,
        opportunity_owner.city opportunity_owner_city,
        opportunity_owner.state as opportunity_owner_state,
        opportunity_manager.user_id as opportunity_manager_id,
        opportunity_manager.user_name as opportunity_manager_name,
        opportunity_manager.city opportunity_manager_city,
        opportunity_manager.state as opportunity_manager_state,

        -- If using user_role table, the following will be included, otherwise it will not.
        {% if var('salesforce__user_role_enabled', True) %}
        user_role.user_role_name as opportunity_owner_position, 
        user_role.developer_name as opportunity_owner_developer_name,
        user_role.parent_role_id as opportunity_owner_parent_role_id,
        user_role.rollup_description as opportunity_owner_rollup_description,
        {% endif %}

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

        {% if var('not_using_salesforce_history_mode', True) %}
        --The below script allows for pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='salesforce__account_pass_through_columns', identifier='account') }}
        {{ custom_persist_pass_through_columns(pass_through_variable='salesforce__user_pass_through_columns', identifier='opportunity_owner', append_string= '_owner') }}
        {{ custom_persist_pass_through_columns(pass_through_variable='salesforce__user_pass_through_columns', identifier='opportunity_manager', append_string= '_manager') }}

        -- If using user_role table, the following will be included, otherwise it will not.
        {% if var('salesforce__user_role_enabled', True) %}
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='salesforce__user_role_pass_through_columns', identifier='user_role') }}
        {% endif %}

        {% else %}
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='salesforce__account_history_pass_through_columns', identifier='account') }}
        {{ custom_persist_pass_through_columns(pass_through_variable='salesforce__user_history_pass_through_columns', identifier='opportunity_owner', append_string= '_owner') }}
        {{ custom_persist_pass_through_columns(pass_through_variable='salesforce__user_history_pass_through_columns', identifier='opportunity_manager', append_string= '_manager') }}

        {% if var('salesforce__user_role_history_enabled', True) %}
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='salesforce__user_role_history_pass_through_columns', identifier='user_role_history') }}
        {% endif %}

        {% endif %}

    from opportunity
    left join account 
        on opportunity.account_id = account.account_id
    left join salesforce_user as opportunity_owner 
        on opportunity.owner_id = opportunity_owner.user_id
    left join salesforce_user as opportunity_manager 
        on opportunity_owner.manager_id = opportunity_manager.user_id

    -- If using user_role table, the following will be included, otherwise it will not.
    {% if var('salesforce__user_role_enabled', True) or var('salesforce__user_role_history_enabled', True) %}
    left join user_role 
        on opportunity_owner.user_role_id = user_role.user_role_id
    {% endif %}
    )

select *
from add_fields
