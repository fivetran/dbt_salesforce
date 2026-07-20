{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{% set exclude_columns = var('consistency_test_exclude_columns', []) %}

/* This test is to make sure the final columns produced are the same between versions.
Only one test is needed since it will fetch all tables and all columns in each schema.
!!! THIS TEST IS WRITTEN FOR BIGQUERY!!! */
with prod as (
    select
        table_name,
        column_name,
        data_type
    from {{ target.schema }}_salesforce_prod.INFORMATION_SCHEMA.COLUMNS
    {% if exclude_columns %}where column_name not in ('{{ exclude_columns | join("', '") }}'){% endif %}
),

dev as (
    select
        table_name,
        column_name,
        data_type
    from {{ target.schema }}_salesforce_dev.INFORMATION_SCHEMA.COLUMNS
    {% if exclude_columns %}where column_name not in ('{{ exclude_columns | join("', '") }}'){% endif %}
),

shared_tables as (
    select table_name from prod
    intersect distinct
    select table_name from dev
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
    select *, 'from prod' as source from prod_not_in_dev
    union all
    select *, 'from dev' as source from dev_not_in_prod
)

-- only surface differences for tables present in both schemas
select *
from final
inner join shared_tables using (table_name)
