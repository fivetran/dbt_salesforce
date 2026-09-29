{% set contact_column_list = get_contact_columns() %}
{% set contact_column_payload = normalize_column_payload(var('salesforce__contact_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(contact_column_list, contact_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__contact_pass_through_columns') }}

    from {{ source('salesforce','contact') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
