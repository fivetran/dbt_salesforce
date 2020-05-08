with base as (

    select *
    from {{ var('account')}}
    where not is_deleted

), fields as (

    select 

      id as account_id,
      name as account_name,
      industry,
      number_of_employees,
      account_source

    from base

)

select *
from fields