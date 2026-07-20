{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{% set exclude_columns = var('consistency_test_exclude_columns', []) %}

-- this test ensures the contact_enhanced end model matches the prior version
with prod as (
    select {{ dbt_utils.star(from=ref('salesforce__contact_enhanced'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_prod.salesforce__contact_enhanced
),

dev as (
    select {{ dbt_utils.star(from=ref('salesforce__contact_enhanced'), except=exclude_columns) }}
    from {{ target.schema }}_salesforce_dev.salesforce__contact_enhanced
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
