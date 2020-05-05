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