{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and (
        var('salesforce__account_history_enabled', false) or
        var('salesforce__campaign_history_enabled', false) or
        var('salesforce__contact_history_enabled', false) or
        var('salesforce__opportunity_history_enabled', false)
    )
) }}

{% set models = [] %}
{% do models.append('salesforce__account_daily_history')     if var('salesforce__account_history_enabled', false) %}
{% do models.append('salesforce__campaign_daily_history')    if var('salesforce__campaign_history_enabled', false) %}
{% do models.append('salesforce__contact_daily_history')     if var('salesforce__contact_history_enabled', false) %}
{% do models.append('salesforce__opportunity_daily_history') if var('salesforce__opportunity_history_enabled', false) %}

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
