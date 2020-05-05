



with __dbt__CTE__stg_salesforce_account as (
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
)select count(*)
from (

    select
        account_id

    from __dbt__CTE__stg_salesforce_account
    where account_id is not null
    group by account_id
    having count(*) > 1

) validation_errors

