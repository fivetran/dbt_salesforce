{% set contact_column_list = get_contact_columns() -%}
{% set contact_dict = column_list_to_dict(contact_column_list) -%}
{% set contact_relation = source('salesforce','contact') %}
{% set contact_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), contact_relation.schema, contact_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(contact_column_list, contact_column_payload)
        }}
        
    from {{ contact_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("id", contact_dict, alias="contact_id") }},
        {{ salesforce.cast_and_alias_column("account_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("department", contact_dict) }},
        {{ salesforce.cast_and_alias_column("description", contact_dict, alias="contact_description") }},
        {{ salesforce.cast_and_alias_column("email", contact_dict) }},
        {{ salesforce.cast_and_alias_column("first_name", contact_dict) }},
        {{ salesforce.cast_and_alias_column("home_phone", contact_dict) }},
        {{ salesforce.cast_and_alias_column("individual_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_activity_date", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_by_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_modified_date", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_name", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", contact_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", contact_dict) }},
        {{ salesforce.cast_and_alias_column("lead_source", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_city", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_country", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_country_code", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_postal_code", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_state", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_state_code", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mailing_street", contact_dict) }},
        {{ salesforce.cast_and_alias_column("master_record_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("mobile_phone", contact_dict) }},
        {{ salesforce.cast_and_alias_column("name", contact_dict, alias="contact_name") }},
        {{ salesforce.cast_and_alias_column("owner_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("phone", contact_dict) }},
        {{ salesforce.cast_and_alias_column("reports_to_id", contact_dict) }},
        {{ salesforce.cast_and_alias_column("title", contact_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__contact_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)