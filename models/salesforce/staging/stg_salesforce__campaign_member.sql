--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

{% set campaign_member_column_list = get_campaign_member_columns() -%}
{% set campaign_member_dict = column_list_to_dict(campaign_member_column_list) -%}

with fields as (

    select

        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('salesforce','campaign_member')),
                staging_columns=campaign_member_column_list
            )
        }}

    from {{ source('salesforce','campaign_member') }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.coalesce_rename("id", campaign_member_dict, alias="campaign_member_id") }},
        {{ salesforce.coalesce_rename("account_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("campaign_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("contact_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("created_by_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("created_date", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("first_responded_date", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("has_opted_out_of_email", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("has_responded", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("is_deleted", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("last_modified_by_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("lead_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("lead_or_contact_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("lead_or_contact_owner_id", campaign_member_dict) }},
        {{ salesforce.coalesce_rename("status", campaign_member_dict) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_member_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
