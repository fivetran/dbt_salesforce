--To disable this model, set the salesforce__campaign_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('campaign', get_campaign_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        id as campaign_id,
        cast(actual_cost as {{ dbt.type_numeric() }}) as actual_cost,
        cast(amount_all_opportunities as {{ dbt.type_numeric() }}) as total_pipeline_amount,
        cast(budgeted_cost as {{ dbt.type_numeric() }}) as budgeted_cost,
        campaign_member_record_type_id,
        description as campaign_description,
        end_date,
        is_active,
        is_deleted,
        name as campaign_name,
        number_of_contacts,
        number_of_converted_leads,
        number_of_leads,
        number_of_opportunities,
        number_of_responses,
        number_of_won_opportunities,
        parent_id as parent_campaign_id,
        start_date,
        status as campaign_status,
        type as campaign_type

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
