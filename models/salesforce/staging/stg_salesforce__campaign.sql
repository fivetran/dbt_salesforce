--To disable this model, set the salesforce__campaign_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__campaign_enabled', True)) }}

{% set campaign_column_list = get_campaign_columns() -%}
{% set campaign_dict = column_list_to_dict(campaign_column_list) -%}
{% set campaign_relation = source('salesforce','campaign') %}
{% set campaign_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), campaign_relation.schema, campaign_relation.identifier) %}

with fields as (

    select

        {{
            apply_column_payload(campaign_column_list, campaign_column_payload)
        }}

    from {{ campaign_relation }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", campaign_dict, alias="campaign_id") }},
        {{ salesforce.cast_and_alias_column("actual_cost", campaign_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("amount_all_opportunities", campaign_dict, alias="total_pipeline_amount", datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("budgeted_cost", campaign_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("campaign_member_record_type_id", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("description", campaign_dict, alias="campaign_description") }},
        {{ salesforce.cast_and_alias_column("end_date", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("is_active", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("name", campaign_dict, alias="campaign_name") }},
        {{ salesforce.cast_and_alias_column("number_of_contacts", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_converted_leads", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_leads", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_opportunities", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_responses", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("number_of_won_opportunities", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("parent_id", campaign_dict, alias="parent_campaign_id") }},
        {{ salesforce.cast_and_alias_column("start_date", campaign_dict) }},
        {{ salesforce.cast_and_alias_column("status", campaign_dict, alias="campaign_status") }},
        {{ salesforce.cast_and_alias_column("type", campaign_dict, alias="campaign_type") }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__campaign_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
