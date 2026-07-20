{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and var('salesforce__campaign_enabled', true)
) }}

-- this test validates that the campaign_performance end model correctly reflects
-- source data: row parity with stg_campaign, member_count from stg_campaign_member,
-- and total_won_amount from stg_opportunity

with end_model as (
    select *
    from {{ target.schema }}_salesforce_dev.salesforce__campaign_performance
),

-- verify 1:1 relationship with staging campaign -- no fanout, no missing rows
campaign_row_parity as (
    select count(*) as end_model_count
    from end_model
),

stg_campaign_count as (
    select count(*) as stg_count
    from {{ target.schema }}_salesforce_dev.stg_salesforce__campaign
),

row_parity_check as (
    select *
    from campaign_row_parity
    join stg_campaign_count
        on campaign_row_parity.end_model_count != stg_campaign_count.stg_count
),

-- verify member_count matches direct count from stg_campaign_member
stg_campaign_member_count as (
    select
        campaign_id,
        count(*) as stg_member_count
    from {{ target.schema }}_salesforce_dev.stg_salesforce__campaign_member
    group by campaign_id
),

member_count_check as (
    select
        end_model.campaign_id,
        end_model.campaign_member_count as end_model_member_count,
        coalesce(stg_campaign_member_count.stg_member_count, 0) as stg_member_count
    from end_model
    left join stg_campaign_member_count
        on end_model.campaign_id = stg_campaign_member_count.campaign_id
    where coalesce(end_model.campaign_member_count, 0) != coalesce(stg_campaign_member_count.stg_member_count, 0)
),

-- verify total_won_amount matches direct sum from stg_opportunity
stg_opportunity_won_amount as (
    select
        campaign_id,
        sum(amount) as stg_won_amount
    from {{ target.schema }}_salesforce_dev.stg_salesforce__opportunity
    where is_won = true
        and campaign_id is not null
    group by campaign_id
),

won_amount_check as (
    select
        end_model.campaign_id,
        end_model.total_won_amount as end_model_won_amount,
        stg_opportunity_won_amount.stg_won_amount
    from end_model
    left join stg_opportunity_won_amount
        on end_model.campaign_id = stg_opportunity_won_amount.campaign_id
    where coalesce(end_model.total_won_amount, 0) != coalesce(stg_opportunity_won_amount.stg_won_amount, 0)
),

final as (
    select campaign_id, 'member_count mismatch' as reason from member_count_check
    union all
    select campaign_id, 'total_won_amount mismatch' as reason from won_amount_check
    union all
    select cast(null as string), 'campaign row count mismatch' as reason from row_parity_check
)

select *
from final
