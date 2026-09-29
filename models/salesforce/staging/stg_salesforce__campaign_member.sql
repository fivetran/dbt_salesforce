--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

{% set campaign_member_column_list = get_campaign_member_columns() %}
{% set campaign_member_column_payload = normalize_column_payload(var('salesforce__campaign_member_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(campaign_member_column_list, campaign_member_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_member_pass_through_columns') }}

    from {{ source('salesforce','campaign_member') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
