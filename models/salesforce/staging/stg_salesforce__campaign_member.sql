--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('campaign_member', get_campaign_member_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        id as campaign_member_id,
        account_id,
        cast(campaign_id as {{ dbt.type_string() }}) as campaign_id,
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
