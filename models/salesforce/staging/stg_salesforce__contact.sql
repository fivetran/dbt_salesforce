with fields as (

    {{ salesforce.select_payload_fields('contact', get_contact_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as contact_id,
        cast(account_id as {{ dbt.type_string() }}) as account_id,
        cast(department as {{ dbt.type_string() }}) as department,
        cast(description as {{ dbt.type_string() }}) as contact_description,
        cast(email as {{ dbt.type_string() }}) as email,
        cast(first_name as {{ dbt.type_string() }}) as first_name,
        cast(home_phone as {{ dbt.type_string() }}) as home_phone,
        cast(individual_id as {{ dbt.type_string() }}) as individual_id,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(last_activity_date as {{ dbt.type_timestamp() }}) as last_activity_date,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(last_name as {{ dbt.type_string() }}) as last_name,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(lead_source as {{ dbt.type_string() }}) as lead_source,
        cast(mailing_city as {{ dbt.type_string() }}) as mailing_city,
        cast(mailing_country as {{ dbt.type_string() }}) as mailing_country,
        cast(mailing_country_code as {{ dbt.type_string() }}) as mailing_country_code,
        cast(mailing_postal_code as {{ dbt.type_string() }}) as mailing_postal_code,
        cast(mailing_state as {{ dbt.type_string() }}) as mailing_state,
        cast(mailing_state_code as {{ dbt.type_string() }}) as mailing_state_code,
        cast(mailing_street as {{ dbt.type_string() }}) as mailing_street,
        cast(master_record_id as {{ dbt.type_string() }}) as master_record_id,
        cast(mobile_phone as {{ dbt.type_string() }}) as mobile_phone,
        cast(name as {{ dbt.type_string() }}) as contact_name,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(phone as {{ dbt.type_string() }}) as phone,
        cast(reports_to_id as {{ dbt.type_string() }}) as reports_to_id,
        cast(title as {{ dbt.type_string() }}) as title

        {{ fivetran_utils.fill_pass_through_columns('salesforce__contact_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)