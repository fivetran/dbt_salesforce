with fields as (

    {{ salesforce.select_payload_fields('salesforce', 'user', get_user_columns()) }}
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
        cast(id as {{ dbt.type_string() }}) as user_id,
        individual_id,
        is_active,
        last_login_date,
        last_name,
        last_referenced_date,
        last_viewed_date,
        cast(manager_id as {{ dbt.type_string() }}) as manager_id,
        cast(name as {{ dbt.type_string() }}) as user_name,
        postal_code,
        profile_id,
        state,
        state_code,
        street,
        title,
        cast(user_role_id as {{ dbt.type_string() }}) as user_role_id,
        user_type,
        username

        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_pass_through_columns') }}
    
    from fields
    where coalesce(_fivetran_active, true)
)

select * 
from final