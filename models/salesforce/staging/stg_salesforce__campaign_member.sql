--To disable this model, set the salesforce__campaign_member_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_member_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('campaign_member', get_campaign_member_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as campaign_member_id,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(campaign_id as {{ dbt.type_string() }}) as campaign_id,
        cast(contact_id as {{ dbt.type_string() }}) as contact_id,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(first_responded_date as {{ dbt.type_timestamp() }}) as first_responded_date,
        cast(has_opted_out_of_email as {{ "boolean" }}) as has_opted_out_of_email,
        cast(has_responded as {{ "boolean" }}) as has_responded,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(lead_id as {{ dbt.type_string() }}) as lead_id,
        cast(lead_or_contact_id as {{ dbt.type_string() }}) as lead_or_contact_id,
        cast(lead_or_contact_owner_id as {{ dbt.type_string() }}) as lead_or_contact_owner_id,
        cast(status as {{ dbt.type_string() }}) as status

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_member_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
