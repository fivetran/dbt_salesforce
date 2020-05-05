

  create or replace view `digital-arbor-400`.`dbt_kristin_test`.`stg_salesforce_user`
  OPTIONS()
  as (
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
  );
