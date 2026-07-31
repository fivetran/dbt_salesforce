{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and var('salesforce__contact_history_enabled', false)
) }}

-- this test confirms two properties of the contact daily history spine:
-- 1) every contact has a continuous daily spine with no gaps between its first and last date_day
-- 2) contacts that are still active (per _fivetran_active) continue to receive a row through the
--    most recently materialized date_day, even if the record hasn't changed recently

with bounds as (

    select
        contact_id,
        min(date_day) as min_date_day,
        max(date_day) as max_date_day,
        count(distinct date_day) as actual_day_count
    from {{ ref('salesforce__contact_daily_history') }}
    group by 1
),

gaps as (

    select
        contact_id,
        'gap in daily spine' as failure_reason
    from bounds
    where actual_day_count != {{ dbt.datediff('min_date_day', 'max_date_day', 'day') }} + 1
),

max_day as (

    select max(date_day) as max_date_day
    from {{ ref('salesforce__contact_daily_history') }}
),

currently_active_contacts as (

    select distinct id as contact_id
    from {{ source('salesforce_history', 'contact') }}
    where _fivetran_active
),

missing_current_row as (

    select
        currently_active_contacts.contact_id,
        'active contact missing a row for the latest date_day' as failure_reason
    from currently_active_contacts
    cross join max_day
    left join {{ ref('salesforce__contact_daily_history') }} as daily_history
        on currently_active_contacts.contact_id = daily_history.contact_id
        and daily_history.date_day = max_day.max_date_day
    where daily_history.contact_day_id is null
)

select * from gaps
union all
select * from missing_current_row
