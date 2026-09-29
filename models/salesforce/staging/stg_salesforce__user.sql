{% set user_column_list = get_user_columns() -%}
{% set user_dict = column_list_to_dict(user_column_list) -%}
{% set user_relation = source('salesforce','user') %}
{% set user_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), user_relation.schema, user_relation.identifier) %}

with fields as (

    select

        {{
            apply_column_payload(user_column_list, user_column_payload)
        }}

    from {{ user_relation }}
), 

final as (
    
    select 
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("account_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("alias", user_dict ) }},
        {{ salesforce.cast_and_alias_column("city", user_dict ) }},
        {{ salesforce.cast_and_alias_column("company_name", user_dict ) }},
        {{ salesforce.cast_and_alias_column("contact_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("country", user_dict ) }},
        {{ salesforce.cast_and_alias_column("country_code", user_dict ) }},
        {{ salesforce.cast_and_alias_column("department", user_dict ) }},
        {{ salesforce.cast_and_alias_column("email", user_dict ) }},
        {{ salesforce.cast_and_alias_column("first_name", user_dict ) }},
        {{ salesforce.cast_and_alias_column("id", user_dict, alias="user_id" ) }},
        {{ salesforce.cast_and_alias_column("individual_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("is_active", user_dict ) }},
        {{ salesforce.cast_and_alias_column("last_login_date", user_dict ) }},
        {{ salesforce.cast_and_alias_column("last_name", user_dict ) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", user_dict ) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", user_dict ) }},
        {{ salesforce.cast_and_alias_column("manager_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("name", user_dict, alias="user_name" ) }},
        {{ salesforce.cast_and_alias_column("postal_code", user_dict ) }},
        {{ salesforce.cast_and_alias_column("profile_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("state", user_dict ) }},
        {{ salesforce.cast_and_alias_column("state_code", user_dict ) }},
        {{ salesforce.cast_and_alias_column("street", user_dict ) }},
        {{ salesforce.cast_and_alias_column("title", user_dict ) }},
        {{ salesforce.cast_and_alias_column("user_role_id", user_dict ) }},
        {{ salesforce.cast_and_alias_column("user_type", user_dict ) }},
        {{ salesforce.cast_and_alias_column("username", user_dict ) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_pass_through_columns') }}
    
    from fields
    where coalesce(_fivetran_active, true)
)

select * 
from final