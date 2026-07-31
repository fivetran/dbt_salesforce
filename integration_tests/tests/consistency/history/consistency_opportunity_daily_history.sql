{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and var('salesforce__opportunity_history_enabled', false)
) }}

{% set exclude_columns = var('consistency_test_exclude_columns', []) %}

-- this test ensures the opportunity_daily_history end model matches the prior version.
-- NOTE: as of the account/contact/opportunity history model consolidation, expect
-- `dev_not_in_prod` rows for: 1) previously-unchanged-but-still-active opportunities that were
-- missing daily rows in prod (the incremental boundary bug fix), and 2) the `description`/
-- `name` columns, now aliased to `opportunity_description`/`opportunity_name`. Use
-- `consistency_test_exclude_columns` to exclude the renamed columns if isolating (1).
with prod as (
    select {{ dbt_utils.star(from=ref('salesforce__opportunity_daily_history'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_prod.salesforce__opportunity_daily_history
    where date(date_day) < date({{ dbt.current_timestamp() }})
),

dev as (
    select {{ dbt_utils.star(from=ref('salesforce__opportunity_daily_history'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_dev.salesforce__opportunity_daily_history
    where date(date_day) < date({{ dbt.current_timestamp() }})
),

prod_not_in_dev as (
    -- rows from prod not found in dev
    select * from prod
    except distinct
    select * from dev
),

dev_not_in_prod as (
    -- rows from dev not found in prod
    select * from dev
    except distinct
    select * from prod
),

final as (
    select
        *,
        'from prod' as source
    from prod_not_in_dev

    union all -- union since we only care if rows are produced

    select
        *,
        'from dev' as source
    from dev_not_in_prod
)

select *
from final
