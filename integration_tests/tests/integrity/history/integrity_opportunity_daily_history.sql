{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and var('salesforce__opportunity_history_enabled', false)
) }}

-- this test confirms two properties of the opportunity daily history spine:
-- 1) every opportunity has a continuous daily spine with no gaps between its first and last date_day
-- 2) opportunities that are still active (per _fivetran_active) continue to receive a row through the
--    most recently materialized date_day, even if the record hasn't changed recently

with bounds as (

    select
        opportunity_id,
        min(date_day) as min_date_day,
        max(date_day) as max_date_day,
        count(distinct date_day) as actual_day_count
    from {{ ref('salesforce__opportunity_daily_history') }}
    group by 1
),

gaps as (

    select
        opportunity_id,
        'gap in daily spine' as failure_reason
    from bounds
    where actual_day_count != {{ dbt.datediff('min_date_day', 'max_date_day', 'day') }} + 1
),

max_day as (

    select max(date_day) as max_date_day
    from {{ ref('salesforce__opportunity_daily_history') }}
),

currently_active_opportunities as (

    select distinct id as opportunity_id
    from {{ source('salesforce_history', 'opportunity') }}
    where _fivetran_active
),

missing_current_row as (

    select
        currently_active_opportunities.opportunity_id,
        'active opportunity missing a row for the latest date_day' as failure_reason
    from currently_active_opportunities
    cross join max_day
    left join {{ ref('salesforce__opportunity_daily_history') }} as daily_history
        on currently_active_opportunities.opportunity_id = daily_history.opportunity_id
        and daily_history.date_day = max_day.max_date_day
    where daily_history.opportunity_day_id is null
)

select * from gaps
union all
select * from missing_current_row
