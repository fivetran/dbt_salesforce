--To disable this model, set the salesforce__lead_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__lead_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('lead', get_lead_columns()) }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as lead_id,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        cast(city as {{ dbt.type_string() }}) as city,
        cast(company as {{ dbt.type_string() }}) as company,
        cast(converted_account_id as {{ dbt.type_string() }}) as converted_account_id,
        cast(converted_contact_id as {{ dbt.type_string() }}) as converted_contact_id,
        cast(converted_date as {{ dbt.type_timestamp() }}) as converted_date,
        cast(converted_opportunity_id as {{ dbt.type_string() }}) as converted_opportunity_id,
        cast(country as {{ dbt.type_string() }}) as country,
        cast(country_code as {{ dbt.type_string() }}) as country_code,
        cast(created_by_id as {{ dbt.type_string() }}) as created_by_id,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        cast(description as {{ dbt.type_string() }}) as lead_description,
        cast(email as {{ dbt.type_string() }}) as email,
        cast(email_bounced_date as {{ dbt.type_timestamp() }}) as email_bounced_date,
        cast(email_bounced_reason as {{ dbt.type_string() }}) as email_bounced_reason,
        cast(first_name as {{ dbt.type_string() }}) as first_name,
        cast(has_opted_out_of_email as {{ "boolean" }}) as has_opted_out_of_email,
        cast(individual_id as {{ dbt.type_string() }}) as individual_id,
        cast(industry as {{ dbt.type_string() }}) as industry,
        cast(is_converted as {{ "boolean" }}) as is_converted,
        cast(is_deleted as {{ "boolean" }}) as is_deleted,
        cast(is_unread_by_owner as {{ "boolean" }}) as is_unread_by_owner,
        cast(last_activity_date as {{ dbt.type_timestamp() }}) as last_activity_date,
        cast(last_modified_by_id as {{ dbt.type_string() }}) as last_modified_by_id,
        cast(last_modified_date as {{ dbt.type_timestamp() }}) as last_modified_date,
        cast(last_name as {{ dbt.type_string() }}) as last_name,
        cast(last_referenced_date as {{ dbt.type_timestamp() }}) as last_referenced_date,
        cast(last_viewed_date as {{ dbt.type_timestamp() }}) as last_viewed_date,
        cast(lead_source as {{ dbt.type_string() }}) as lead_source,
        cast(master_record_id as {{ dbt.type_string() }}) as master_record_id,
        cast(mobile_phone as {{ dbt.type_string() }}) as mobile_phone,
        cast(name as {{ dbt.type_string() }}) as lead_name,
        cast(number_of_employees as {{ dbt.type_int() }}) as number_of_employees,
        cast(owner_id as {{ dbt.type_string() }}) as owner_id,
        cast(phone as {{ dbt.type_string() }}) as phone,
        cast(postal_code as {{ dbt.type_string() }}) as postal_code,
        cast(state as {{ dbt.type_string() }}) as state,
        cast(state_code as {{ dbt.type_string() }}) as state_code,
        cast(status as {{ dbt.type_string() }}) as status,
        cast(street as {{ dbt.type_string() }}) as street,
        cast(title as {{ dbt.type_string() }}) as title,
        cast(website as {{ dbt.type_string() }}) as website

        {{ fivetran_utils.fill_pass_through_columns('salesforce__lead_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)