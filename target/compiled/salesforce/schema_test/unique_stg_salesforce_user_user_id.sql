



with __dbt__CTE__stg_salesforce_user as (
with base as (

    select *
    from salesforce.user

), fields as (

    select 
      id as user_id,
      name,
      city,
      state,
      manager_id,
      user_role_id
    from base

)

select *
from fields
)select count(*)
from (

    select
        user_id

    from __dbt__CTE__stg_salesforce_user
    where user_id is not null
    group by user_id
    having count(*) > 1

) validation_errors

