--This model will only run if you have the underlying campaign table.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

with campaign as (

    select *
    from {{ ref('stg_salesforce__campaign') }}
),

opportunity as (

    select
        campaign_id,
        amount
    from {{ ref('stg_salesforce__opportunity') }}
    where is_won = true
        and campaign_id is not null
),

{% if var('salesforce__campaign_member_enabled', True) %}
campaign_member as (

    select
        campaign_id,
        count(*) as member_count
    from {{ ref('stg_salesforce__campaign_member') }}
    group by 1
),
{% endif %}

{% if var('salesforce__record_type_enabled', True) %}
record_type as (

    select *
    from {{ ref('stg_salesforce__record_type') }}
),
{% endif %}

won_opportunity_agg as (

    select
        campaign_id,
        sum(amount) as total_won_amount
    from opportunity
    group by 1
),

final as (

    select
        campaign.campaign_id,
        campaign.campaign_name,
        campaign.campaign_type,
        campaign.campaign_status,
        campaign.start_date,
        campaign.end_date,
        campaign.is_active,
        campaign.parent_campaign_id,
        campaign.budgeted_cost,
        campaign.actual_cost,
        campaign.number_of_leads,
        campaign.number_of_converted_leads,
        campaign.number_of_contacts,
        campaign.number_of_responses,
        campaign.number_of_opportunities,
        campaign.number_of_won_opportunities,
        campaign.total_pipeline_amount,
        campaign.record_type_id,

        {% if var('salesforce__record_type_enabled', True) %}
        record_type.record_type_name,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as record_type_name,
        {% endif %}

        {% if var('salesforce__campaign_member_enabled', True) %}
        campaign_member.member_count,
        {% else %}
        cast(null as {{ dbt.type_int() }}) as member_count,
        {% endif %}

        won_opportunity_agg.total_won_amount,

        -- Derived metrics
        campaign.number_of_won_opportunities / nullif(campaign.number_of_opportunities, 0) as win_rate,
        campaign.actual_cost / nullif(campaign.number_of_opportunities, 0) as cost_per_opportunity,
        campaign.actual_cost / nullif(campaign.number_of_won_opportunities, 0) as cost_per_won_opportunity,
        (won_opportunity_agg.total_won_amount - campaign.actual_cost) / nullif(campaign.actual_cost, 0) as roi

    from campaign
    left join won_opportunity_agg
        on campaign.campaign_id = won_opportunity_agg.campaign_id
    {% if var('salesforce__campaign_member_enabled', True) %}
    left join campaign_member
        on campaign.campaign_id = campaign_member.campaign_id
    {% endif %}
    {% if var('salesforce__record_type_enabled', True) %}
    left join record_type
        on campaign.record_type_id = record_type.record_type_id
    {% endif %}
)

select *
from final
