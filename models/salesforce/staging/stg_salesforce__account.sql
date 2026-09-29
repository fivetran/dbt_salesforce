{% set account_column_list = get_account_columns() -%}
{% set account_dict = column_list_to_dict(account_column_list) -%}
{% set account_relation = source('salesforce','account') %}
{% set account_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), account_relation.schema, account_relation.identifier) %}

with fields as (

    select
        {{
            apply_column_payload(account_column_list, account_column_payload)
        }}

    from {{ account_relation }}
), 

final as (
    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("account_number", account_dict) }},
        {{ salesforce.cast_and_alias_column("account_source", account_dict) }},
        {{ salesforce.cast_and_alias_column("annual_revenue", account_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("billing_city", account_dict) }},
        {{ salesforce.cast_and_alias_column("billing_country", account_dict) }},
        {{ salesforce.cast_and_alias_column("billing_postal_code", account_dict) }},
        {{ salesforce.cast_and_alias_column("billing_state", account_dict) }},
        {{ salesforce.cast_and_alias_column("billing_state_code", account_dict) }},
        {{ salesforce.cast_and_alias_column("billing_street", account_dict) }},
        {{ salesforce.cast_and_alias_column("description", account_dict, alias="account_description" ) }},
        {{ salesforce.cast_and_alias_column("id", account_dict, alias="account_id") }},
        {{ salesforce.cast_and_alias_column("industry", account_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", account_dict) }},
        {{ salesforce.cast_and_alias_column("last_activity_date", account_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", account_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", account_dict) }},
        {{ salesforce.cast_and_alias_column("master_record_id", account_dict) }},
        {{ salesforce.cast_and_alias_column("name", account_dict, alias="account_name" ) }},
        {{ salesforce.cast_and_alias_column("number_of_employees", account_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", account_dict) }},
        {{ salesforce.cast_and_alias_column("ownership", account_dict) }},
        {{ salesforce.cast_and_alias_column("parent_id", account_dict) }},
        {{ salesforce.cast_and_alias_column("rating", account_dict) }},
        {{ salesforce.cast_and_alias_column("record_type_id", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_city", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_country", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_country_code", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_postal_code", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_state", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_state_code", account_dict) }},
        {{ salesforce.cast_and_alias_column("shipping_street", account_dict) }},
        {{ salesforce.cast_and_alias_column("type", account_dict) }},
        {{ salesforce.cast_and_alias_column("website", account_dict) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)