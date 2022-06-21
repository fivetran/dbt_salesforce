with contact as (

    select *
    from {{ var('contact') }}
), 

select 
    _fivetran_synced,
    contact_id,
    account_id,
    department,
    description,
    email,
    individual_id,
    is_deleted,
    last_activity_date,
    lead_source,
    master_record_id,
    name,
    owner_id,
    phone,
    reports_to_id

from contact