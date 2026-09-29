--To disable this model, set the salesforce__campaign_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('campaign', get_campaign_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as campaign_id,
        cast(actual_cost as {{ dbt.type_numeric() }}) as actual_cost,
        cast(amount_all_opportunities as {{ dbt.type_numeric() }}) as total_pipeline_amount,
        cast(budgeted_cost as {{ dbt.type_numeric() }}) as budgeted_cost,
        cast(campaign_member_record_type_id as {{ dbt.type_string() }}) as campaign_member_record_type_id,
        cast(description as {{ dbt.type_string() }}) as campaign_description,
        cast(end_date as {{ dbt.type_timestamp() }}) as end_date,
        cast(is_active as {{ "boolean" }}) as is_active,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(name as {{ dbt.type_string() }}) as campaign_name,
        cast(number_of_contacts as {{ dbt.type_int() }}) as number_of_contacts,
        cast(number_of_converted_leads as {{ dbt.type_int() }}) as number_of_converted_leads,
        cast(number_of_leads as {{ dbt.type_int() }}) as number_of_leads,
        cast(number_of_opportunities as {{ dbt.type_int() }}) as number_of_opportunities,
        cast(number_of_responses as {{ dbt.type_int() }}) as number_of_responses,
        cast(number_of_won_opportunities as {{ dbt.type_int() }}) as number_of_won_opportunities,
        cast(parent_id as {{ dbt.type_string() }}) as parent_campaign_id,
        cast(start_date as {{ dbt.type_timestamp() }}) as start_date,
        cast(status as {{ dbt.type_string() }}) as campaign_status,
        cast(type as {{ dbt.type_string() }}) as campaign_type

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
