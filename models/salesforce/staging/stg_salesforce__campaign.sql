--To disable this model, set the salesforce__campaign_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

{% set campaign_column_list = get_campaign_columns() %}
{% set campaign_column_payload = normalize_column_payload(var('salesforce__campaign_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(campaign_column_list, campaign_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_pass_through_columns') }}

    from {{ source('salesforce','campaign') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
