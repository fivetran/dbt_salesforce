--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

{% set campaign_member_column_list = get_campaign_member_columns() -%}
{% set campaign_member_source = source('salesforce','campaign_member') %}
{% set campaign_member_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), campaign_member_source.schema, 'campaign_member') %}
{% set campaign_member_relation = api.Relation.create(database=campaign_member_source.database, schema=campaign_member_source.schema, identifier=campaign_member_column_payload.get('__identifier__', 'campaign_member')) %}

with fields as (

    select

        {{
            apply_column_payload(campaign_member_column_list, campaign_member_column_payload)
        }}

    from {{ campaign_member_relation }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        id as campaign_member_id,
        account_id,
        campaign_id,
        contact_id,
        created_by_id,
        created_date,
        first_responded_date,
        has_opted_out_of_email,
        has_responded,
        is_deleted,
        last_modified_by_id,
        lead_id,
        lead_or_contact_id,
        lead_or_contact_owner_id,
        status

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_member_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
