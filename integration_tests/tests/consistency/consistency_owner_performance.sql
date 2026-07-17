{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{% set float_cols = ['avg_days_to_close', 'avg_days_open', 'win_percent_this_month', 'win_percent_this_quarter', 'total_win_percent'] %}
{% set exclude_columns = var('consistency_test_exclude_columns', []) + float_cols %}

-- non-float columns use exact match; float columns use abs(diff) < 1 tolerance to avoid floating point precision issues
with prod as (
    select {{ dbt_utils.star(from=ref('salesforce__owner_performance'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_prod.salesforce__owner_performance
),

dev as (
    select {{ dbt_utils.star(from=ref('salesforce__owner_performance'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_dev.salesforce__owner_performance
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
    select owner_id, avg_days_to_close, avg_days_open, win_percent_this_month, win_percent_this_quarter, total_win_percent
    from {{ target.schema }}_salesforce_prod.salesforce__owner_performance
),

dev_floats as (
    select owner_id, avg_days_to_close, avg_days_open, win_percent_this_month, win_percent_this_quarter, total_win_percent
    from {{ target.schema }}_salesforce_dev.salesforce__owner_performance
),

float_failures as (
    select prod_floats.owner_id
    from prod_floats
    inner join dev_floats using (owner_id)
    where abs(prod_floats.avg_days_to_close - dev_floats.avg_days_to_close) >= 0.01
        or abs(prod_floats.avg_days_open - dev_floats.avg_days_open) >= 0.01
        or abs(prod_floats.win_percent_this_month - dev_floats.win_percent_this_month) >= 0.01
        or abs(prod_floats.win_percent_this_quarter - dev_floats.win_percent_this_quarter) >= 0.01
        or abs(prod_floats.total_win_percent - dev_floats.total_win_percent) >= 0.01
)

select owner_id from prod_not_in_dev
union all
select owner_id from dev_not_in_prod
union all
select owner_id from float_failures
