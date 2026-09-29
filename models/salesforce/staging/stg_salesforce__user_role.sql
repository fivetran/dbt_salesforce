--To disable this model, set the salesforce__user_role_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__user_role_enabled', True)) }}

{% set user_role_column_list = get_user_role_columns() -%}
{% set user_role_relation = source('salesforce','user_role') %}
{% set user_role_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), user_role_relation.schema, user_role_relation.identifier) %}

with fields as (

    select
        
        {{
            apply_column_payload(user_role_column_list, user_role_column_payload)
        }}

    from {{ user_role_relation }}
), 

final as (

    select
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        developer_name,
        id as user_role_id,
        name as user_role_name,
        opportunity_access_for_account_owner,
        parent_role_id,
        rollup_description
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_role_pass_through_columns') }}
        
    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final