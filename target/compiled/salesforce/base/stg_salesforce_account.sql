with base as (

    select *
    from salesforce.account
    where not is_deleted

), fields as (

    select 

      id as account_id,
      name as account_name,
      industry,
      number_of_employees,
      account_source,
      rating as account_rating,
      annual_revenue

    from base

)

select *
from fields