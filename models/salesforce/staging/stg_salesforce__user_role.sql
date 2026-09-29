--To disable this model, set the salesforce__user_role_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__user_role_enabled', True)) }}

{% set user_role_column_list = get_user_role_columns() %}
{% set user_role_column_payload = normalize_column_payload(var('salesforce__user_role_column_payload', {})) %}

with final as (

    select
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(user_role_column_list, user_role_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_role_pass_through_columns') }}

    from {{ source('salesforce','user_role') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
