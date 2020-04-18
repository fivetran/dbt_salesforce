with user as (

    select *
    from {{ source('salesforce', 'user') }}

), fields as (

    select 

      user.id as user_id,
      name,
      city,
      state,
      manager_id,
      user_role_id

    from user
    where not _fivetran_deleted

)

select *
from fields
