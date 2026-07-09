--To disable this model, set the salesforce__campaign_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

{% set campaign_column_list = get_campaign_columns() -%}
{% set campaign_dict = column_list_to_dict(campaign_column_list) -%}

with fields as (

    select

        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('salesforce','campaign')),
                staging_columns=campaign_column_list
            )
        }}

    from {{ source('salesforce','campaign') }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.coalesce_rename("actual_cost", campaign_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.coalesce_rename("amount_all_opportunities", campaign_dict, alias="total_pipeline_amount", datatype=dbt.type_numeric()) }},
        {{ salesforce.coalesce_rename("budgeted_cost", campaign_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.coalesce_rename("description", campaign_dict, alias="campaign_description") }},
        {{ salesforce.coalesce_rename("end_date", campaign_dict) }},
        {{ salesforce.coalesce_rename("id", campaign_dict, alias="campaign_id") }},
        {{ salesforce.coalesce_rename("is_active", campaign_dict) }},
        {{ salesforce.coalesce_rename("is_deleted", campaign_dict) }},
        {{ salesforce.coalesce_rename("name", campaign_dict, alias="campaign_name") }},
        {{ salesforce.coalesce_rename("number_of_contacts", campaign_dict) }},
        {{ salesforce.coalesce_rename("number_of_converted_leads", campaign_dict) }},
        {{ salesforce.coalesce_rename("number_of_leads", campaign_dict) }},
        {{ salesforce.coalesce_rename("number_of_opportunities", campaign_dict) }},
        {{ salesforce.coalesce_rename("number_of_responses", campaign_dict) }},
        {{ salesforce.coalesce_rename("number_of_won_opportunities", campaign_dict) }},
        {{ salesforce.coalesce_rename("parent_id", campaign_dict, alias="parent_campaign_id") }},
        {{ salesforce.coalesce_rename("record_type_id", campaign_dict) }},
        {{ salesforce.coalesce_rename("start_date", campaign_dict) }},
        {{ salesforce.coalesce_rename("status", campaign_dict, alias="campaign_status") }},
        {{ salesforce.coalesce_rename("type", campaign_dict, alias="campaign_type") }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
