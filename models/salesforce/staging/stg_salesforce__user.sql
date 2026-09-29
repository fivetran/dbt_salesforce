{% set user_column_list = get_user_columns() %}
{% set user_column_payload = normalize_column_payload(var('salesforce__user_column_payload', {})) %}

with final as (

    select
        _fivetran_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(user_column_list, user_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__user_pass_through_columns') }}

    from {{ source('salesforce','user') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
