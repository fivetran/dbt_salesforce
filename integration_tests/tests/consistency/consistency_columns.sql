{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

/* This test is to make sure the final columns produced are the same between versions.
Only one test is needed since it will fetch all tables and all columns in each schema.
!!! THIS TEST IS WRITTEN FOR BIGQUERY!!! */
{% if target.type == 'bigquery' %}
with prod as (
    select
        table_name,
        column_name,
        /* Need the case since the prod version is uncasted, and bigquery automatically produces a value of "bignumeric" or "float"
        while the dev is casted as dbt.type_numeric() and produces a value of "numeric" */
        case when lower(data_type) like '%numeric%' or lower(data_type) like '%float%' then 'numeric'
            else data_type 
            end as data_type
    from {{ target.schema }}_salesforce_prod.INFORMATION_SCHEMA.COLUMNS
),

dev as (
    select
        table_name,
        column_name,
        case when lower(data_type) like '%numeric%' or lower(data_type) like '%float%' then 'numeric'
            else data_type 
            end as data_type
    from {{ target.schema }}_salesforce_dev.INFORMATION_SCHEMA.COLUMNS
),

final as (
    -- test will fail if any rows from prod are not found in dev
    (select * from prod
    except distinct
    select * from dev)

    union all -- union since we only care if rows are produced

    -- test will fail if any rows from dev are not found in prod
    (select * from dev
    except distinct
    select * from prod)
)

select *
from final

{% else %}
{{ print('This is written to run on bigquery. If you need to run on another warehouse, add another version for that warehouse') }}

{% endif %}