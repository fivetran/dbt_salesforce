with account as (

    select *
    from {{ source('salesforce', 'account') }}

), fields as (

    select 

      account.id as account_id,
      name as account_name,
      industry,
      number_of_employees,
      -- account_source --confirm that this exists across all connectors
      -- rating as account_rating, --confirm that this exists across all connectors
      annual_revenue

    from account
    where not is_deleted

)

select *
from fields