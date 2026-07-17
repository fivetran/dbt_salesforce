{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- always-enabled models
{% set models = [
    'salesforce__contact_enhanced',
    'salesforce__daily_activity',
    'salesforce__manager_performance',
    'salesforce__opportunity_enhanced',
    'salesforce__owner_performance',
    'salesforce__sales_snapshot',
] %}

-- conditionally-enabled models
{% do models.append('salesforce__campaign_performance') if var('salesforce__campaign_enabled', true) %}
{% do models.append('salesforce__opportunity_line_item_enhanced') if var('salesforce__opportunity_line_item_enabled', true) %}

with row_counts as (

    {% for model in models %}
    select
        '{{ model }}' as model_name,
        (select count(*) from {{ target.schema }}_salesforce_prod.{{ model }}) as prod_rows,
        (select count(*) from {{ target.schema }}_salesforce_dev.{{ model }}) as dev_rows
    {% if not loop.last %}union all{% endif %}
    {% endfor %}

)

-- test will return values and fail if any row counts don't match
select
    model_name,
    prod_rows,
    dev_rows,
    prod_rows - dev_rows as row_difference
from row_counts
where prod_rows != dev_rows
