--To disable this model, set the salesforce__user_role_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__user_role_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('user_role', get_user_role_columns()) }}
), 

final as (

    select
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(developer_name as {{ dbt.type_string() }}) as developer_name,
        cast(id as {{ dbt.type_string() }}) as user_role_id,
        cast(name as {{ dbt.type_string() }}) as user_role_name,
        cast(opportunity_access_for_account_owner as {{ dbt.type_string() }}) as opportunity_access_for_account_owner,
        cast(parent_role_id as {{ dbt.type_string() }}) as parent_role_id,
        cast(rollup_description as {{ dbt.type_string() }}) as rollup_description

        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_role_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final