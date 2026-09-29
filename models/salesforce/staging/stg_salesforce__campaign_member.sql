--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

{% set campaign_member_column_list = get_campaign_member_columns() -%}
{% set campaign_member_dict = column_list_to_dict(campaign_member_column_list) -%}
{% set campaign_member_relation = source('salesforce','campaign_member') %}
{% set campaign_member_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), campaign_member_relation.schema, campaign_member_relation.identifier) %}

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
        {{ salesforce.cast_and_alias_column("id", campaign_member_dict, alias="campaign_member_id") }},
        {{ salesforce.cast_and_alias_column("account_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("campaign_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("contact_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("created_by_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("first_responded_date", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("has_opted_out_of_email", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("has_responded", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("lead_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("lead_or_contact_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("lead_or_contact_owner_id", campaign_member_dict) }},
        {{ salesforce.cast_and_alias_column("status", campaign_member_dict) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_member_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
