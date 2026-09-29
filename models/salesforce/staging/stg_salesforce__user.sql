{% set user_column_list = get_user_columns() -%}
{% set user_source = source('salesforce','user') %}
{% set user_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), user_source.schema, 'user') %}
{% set user_relation = api.Relation.create(database=user_source.database, schema=user_source.schema, identifier=user_column_payload.get('__identifier__', 'user')) %}

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
        account_id,
        alias,
        city,
        company_name,
        contact_id,
        country,
        country_code,
        department,
        email,
        first_name,
        id as user_id,
        individual_id,
        is_active,
        last_login_date,
        last_name,
        last_referenced_date,
        last_viewed_date,
        manager_id,
        name as user_name,
        postal_code,
        profile_id,
        state,
        state_code,
        street,
        title,
        user_role_id,
        user_type,
        username
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_pass_through_columns') }}
    
    from fields
    where coalesce(_fivetran_active, true)
)

select * 
from final