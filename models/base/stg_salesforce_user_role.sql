with user_role as (

    select *
    from {{ source('salesforce', 'user_role') }}

), fields as (

    select 

      id as user_role_id,
      name as role_name,

    from user_role
    where not _fivetran_deleted

)

select *
from fields