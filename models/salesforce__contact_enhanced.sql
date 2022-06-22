with contact as (

    select *
    from {{ var('contact') }}
), 

account as (

    select *
    from {{ var('account') }}
),

user as (

    select *
    from {{ var('user') }}
)

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
    reports_to_id,
    account.account_number,
    account.account_source,
    account.annual_revenue,
    account.billing_city,
    account.billing_country,
    account.billing_postal_code,
    account.billing_state,
    account.billing_state_code,
    account.billing_street,
    account.description,
    account.account_id,
    account.industry,
    account.is_deleted,
    account.last_activity_date,
    account.account_name,
    account.number_of_employees,
    account.owner_id,
    account.ownership,
    account.parent_id,
    account.rating,
    account.record_type_id,
    account.type,
    account.website,
    user.user_name as owner_name,


from contact
left join account 
    on contact.account_id = account.account_id
left join user
    on contact.owner_id = user.user_id