



with __dbt__CTE__stg_salesforce_user_role as (
with base as (

    select *
    from salesforce.user_role
    where not _fivetran_deleted

), fields as (

    select 

      id as user_role_id,
      name as role_name

    from base

)

select *
from fields
)select count(*)
from (

    select
        user_role_id

    from __dbt__CTE__stg_salesforce_user_role
    where user_role_id is not null
    group by user_role_id
    having count(*) > 1

) validation_errors

