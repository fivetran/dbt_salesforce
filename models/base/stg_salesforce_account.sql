with account as (

    select *
    from {{ source('salesforce', 'account') }}

), fields as (

    select 

      account.id as account_id,
      name as account_name,
      industry as industry,
      number_of_employees as number_of_employeees,
      account_source as account_source,
      rating as account_rating,
      annual_revenue as annual_revenue

    from account
    where not is_deleted

)

select *
from fields