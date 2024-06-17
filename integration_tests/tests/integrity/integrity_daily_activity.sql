{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure there is no fanout between the spine and the daily_activity
with spine as (
    select count(*) as spine_count
    from {{ target.schema }}_salesforce_dev.int_salesforce__date_spine
),

daily_activity as (
    select count(*) as daily_activity_count
    from {{ target.schema }}_salesforce_dev.salesforce__daily_activity
)

-- test will return values and fail if the row counts don't match
select *
from spine
join daily_activity
    on spine.spine_count != daily_activity.daily_activity_count