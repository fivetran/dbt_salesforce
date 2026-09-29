--To disable this model, set the salesforce__lead_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__lead_enabled', True)) }}

{% set lead_column_list = get_lead_columns() -%}
{% set lead_dict = column_list_to_dict(lead_column_list) -%}
{% set lead_relation = source('salesforce','lead') %}
{% set lead_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), lead_relation.schema, lead_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(lead_column_list, lead_column_payload)
        }}
        
    from {{ lead_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", lead_dict, alias="lead_id") }},
        {{ salesforce.cast_and_alias_column("annual_revenue", lead_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("city", lead_dict) }},
        {{ salesforce.cast_and_alias_column("company", lead_dict) }},
        {{ salesforce.cast_and_alias_column("converted_account_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("converted_contact_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("converted_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("converted_opportunity_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("country", lead_dict) }},
        {{ salesforce.cast_and_alias_column("country_code", lead_dict) }},
        {{ salesforce.cast_and_alias_column("created_by_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("description", lead_dict, alias="lead_description") }},
        {{ salesforce.cast_and_alias_column("email", lead_dict) }},
        {{ salesforce.cast_and_alias_column("email_bounced_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("email_bounced_reason", lead_dict) }},
        {{ salesforce.cast_and_alias_column("first_name", lead_dict) }},
        {{ salesforce.cast_and_alias_column("has_opted_out_of_email", lead_dict) }},
        {{ salesforce.cast_and_alias_column("individual_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("industry", lead_dict) }},
        {{ salesforce.cast_and_alias_column("is_converted", lead_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", lead_dict) }},
        {{ salesforce.cast_and_alias_column("is_unread_by_owner", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_activity_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_name", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", lead_dict) }},
        {{ salesforce.cast_and_alias_column("lead_source", lead_dict) }},
        {{ salesforce.cast_and_alias_column("master_record_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("mobile_phone", lead_dict) }},
        {{ salesforce.cast_and_alias_column("name", lead_dict, alias="lead_name") }},
        {{ salesforce.cast_and_alias_column("number_of_employees", lead_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", lead_dict) }},
        {{ salesforce.cast_and_alias_column("phone", lead_dict) }},
        {{ salesforce.cast_and_alias_column("postal_code", lead_dict) }},
        {{ salesforce.cast_and_alias_column("state", lead_dict) }},
        {{ salesforce.cast_and_alias_column("state_code", lead_dict) }},
        {{ salesforce.cast_and_alias_column("status", lead_dict) }},
        {{ salesforce.cast_and_alias_column("street", lead_dict) }},
        {{ salesforce.cast_and_alias_column("title", lead_dict) }},
        {{ salesforce.cast_and_alias_column("website", lead_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__lead_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)