{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{% set float_cols = ['avg_days_to_close', 'avg_days_open'] %}
{% set exclude_columns = var('consistency_test_exclude_columns', []) + float_cols %}

-- non-float columns use exact match; float columns use abs(diff) < 1 tolerance to avoid floating point precision issues
-- sales_snapshot is a single-row model so float_failures uses a cross join
with prod as (
    select {{ dbt_utils.star(from=ref('salesforce__sales_snapshot'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_prod.salesforce__sales_snapshot
),

dev as (
    select {{ dbt_utils.star(from=ref('salesforce__sales_snapshot'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_dev.salesforce__sales_snapshot
),

prod_not_in_dev as (
    select * from prod
    except distinct
    select * from dev
),

dev_not_in_prod as (
    select * from dev
    except distinct
    select * from prod
),

prod_floats as (
    select avg_days_to_close, avg_days_open
    from {{ target.schema }}_salesforce_prod.salesforce__sales_snapshot
),

dev_floats as (
    select avg_days_to_close, avg_days_open
    from {{ target.schema }}_salesforce_dev.salesforce__sales_snapshot
),

float_failures as (
    select 1 as placeholder
    from prod_floats
    cross join dev_floats
    where abs(prod_floats.avg_days_to_close - dev_floats.avg_days_to_close) >= 0.01
        or abs(prod_floats.avg_days_open - dev_floats.avg_days_open) >= 0.01
)

select 1 from prod_not_in_dev
union all
select 1 from dev_not_in_prod
union all
select placeholder from float_failures
