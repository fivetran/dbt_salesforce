--To disable this model, set the salesforce__lead_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__lead_enabled', True)) }}

{% set lead_column_list = get_lead_columns() -%}
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
        id as lead_id,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        city,
        company,
        converted_account_id,
        converted_contact_id,
        converted_date,
        converted_opportunity_id,
        country,
        country_code,
        created_by_id,
        created_date,
        description as lead_description,
        email,
        email_bounced_date,
        email_bounced_reason,
        first_name,
        has_opted_out_of_email,
        individual_id,
        industry,
        is_converted,
        is_deleted,
        is_unread_by_owner,
        last_activity_date,
        last_modified_by_id,
        last_modified_date,
        last_name,
        last_referenced_date,
        last_viewed_date,
        lead_source,
        master_record_id,
        mobile_phone,
        name as lead_name,
        number_of_employees,
        owner_id,
        phone,
        postal_code,
        state,
        state_code,
        status,
        street,
        title,
        website
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__lead_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)