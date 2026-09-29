with fields as (

    {{ salesforce.select_payload_fields('user', get_user_columns()) }}
), 

final as (
    
    select 
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(alias as {{ dbt.type_string() }}) as alias,
        cast(city as {{ dbt.type_string() }}) as city,
        cast(company_name as {{ dbt.type_string() }}) as company_name,
        cast(contact_id as {{ dbt.type_string() }}) as contact_id,
        cast(country as {{ dbt.type_string() }}) as country,
        cast(country_code as {{ dbt.type_string() }}) as country_code,
        cast(department as {{ dbt.type_string() }}) as department,
        cast(email as {{ dbt.type_string() }}) as email,
        cast(first_name as {{ dbt.type_string() }}) as first_name,
        cast(id as {{ dbt.type_string() }}) as user_id,
        cast(individual_id as {{ dbt.type_string() }}) as individual_id,
        cast(is_active as {{ "boolean" }}) as is_active,
        cast(last_login_date as {{ dbt.type_timestamp() }}) as last_login_date,
        cast(last_name as {{ dbt.type_string() }}) as last_name,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(manager_id as {{ dbt.type_string() }}) as manager_id,
        cast(name as {{ dbt.type_string() }}) as user_name,
        cast(postal_code as {{ dbt.type_string() }}) as postal_code,
        cast(profile_id as {{ dbt.type_string() }}) as profile_id,
        cast(state as {{ dbt.type_string() }}) as state,
        cast(state_code as {{ dbt.type_string() }}) as state_code,
        cast(street as {{ dbt.type_string() }}) as street,
        cast(title as {{ dbt.type_string() }}) as title,
        cast(user_role_id as {{ dbt.type_string() }}) as user_role_id,
        cast(user_type as {{ dbt.type_string() }}) as user_type,
        cast(username as {{ dbt.type_string() }}) as username

        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_pass_through_columns') }}
    
    from fields
    where coalesce(_fivetran_active, true)
)

select * 
from final