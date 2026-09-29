{% set account_column_list = get_account_columns() %}
{% set account_column_payload = normalize_column_payload(var('salesforce__account_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(account_column_list, account_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from {{ source('salesforce','account') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
