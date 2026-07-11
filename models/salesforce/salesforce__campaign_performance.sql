--This model will only run if you have the underlying campaign table.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

{% set campaign_member_enabled = var('salesforce__campaign_member_enabled', True) %}
{% set record_type_enabled = var('salesforce__record_type_enabled', True) %}

with campaign as (

    select *
    from {{ ref('stg_salesforce__campaign') }}
),

opportunity as (

    select
        campaign_id,
        sum(amount) as total_won_amount
    from {{ ref('stg_salesforce__opportunity') }}
    where is_won = true
        and campaign_id is not null
    group by 1
),

{% if campaign_member_enabled %}
campaign_member as (

    select
        campaign_id,
        count(*) as campaign_member_count,
        sum(case when has_opted_out_of_email then 1 else 0 end) as opted_out_of_email_count,
        sum(case when has_responded then 1 else 0 end) as responded_count,
        count(contact_id) as contact_count,
        count(lead_id) as lead_count
    from {{ ref('stg_salesforce__campaign_member') }}
    group by 1
),
{% endif %}

{% if record_type_enabled %}
record_type as (

    select *
    from {{ ref('stg_salesforce__record_type') }}
),
{% endif %}

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

        {% if campaign_member_enabled %}
        campaign_member.campaign_member_count,
        campaign_member.opted_out_of_email_count,
        campaign_member.responded_count,
        campaign_member.contact_count,
        campaign_member.lead_count,
        {% endif %}

        {% if record_type_enabled %}
        record_type.record_type_name as campaign_member_record_type_name,
        {% endif %}

        opportunity.total_won_amount,

        -- Derived metrics
        {{ dbt_utils.safe_divide('campaign.number_of_won_opportunities', 'campaign.number_of_opportunities') }} as win_rate,
        {{ dbt_utils.safe_divide('campaign.actual_cost', 'campaign.number_of_opportunities') }} as cost_per_opportunity,
        {{ dbt_utils.safe_divide('campaign.actual_cost', 'campaign.number_of_won_opportunities') }} as cost_per_won_opportunity,
        {{ dbt_utils.safe_divide('(opportunity.total_won_amount - campaign.actual_cost)', 'campaign.actual_cost') }} as roi

        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='salesforce__campaign_pass_through_columns', identifier='campaign') }}

    from campaign
    left join opportunity
        on campaign.campaign_id = opportunity.campaign_id
    
    {% if campaign_member_enabled %}
    left join campaign_member
        on campaign.campaign_id = campaign_member.campaign_id
    {% endif %}

    {% if record_type_enabled %}
    left join record_type
        on campaign.campaign_member_record_type_id = record_type.record_type_id
    {% endif %}
)

select *
from final
