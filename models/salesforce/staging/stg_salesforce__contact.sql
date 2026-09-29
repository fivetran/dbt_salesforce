{% set contact_column_list = get_contact_columns() -%}
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
        id as contact_id,
        account_id,
        department,
        description as contact_description,
        email,
        first_name,
        home_phone,
        individual_id,
        is_deleted,
        last_activity_date,
        last_modified_by_id,
        last_modified_date,
        last_name,
        last_referenced_date,
        last_viewed_date,
        lead_source,
        mailing_city,
        mailing_country,
        mailing_country_code,
        mailing_postal_code,
        mailing_state,
        mailing_state_code,
        mailing_street,
        master_record_id,
        mobile_phone,
        name as contact_name,
        owner_id,
        phone,
        reports_to_id,
        title
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__contact_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)