{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure the rows counts are the same between versions
with prod as (
    select count(*) as prod_rows
    from {{ target.schema }}_salesforce_prod.salesforce__daily_activity
),

dev as (
    select count(*) as dev_rows
    from {{ target.schema }}_salesforce_dev.salesforce__daily_activity
)

-- test will return values and fail if the row counts don't match
select *
from prod
join dev
    on prod.prod_rows != dev.dev_rows