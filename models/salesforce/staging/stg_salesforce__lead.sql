--To disable this model, set the salesforce__lead_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__lead_enabled', True)) }}

{% set lead_column_list = get_lead_columns() %}
{% set lead_column_payload = normalize_column_payload(var('salesforce__lead_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(lead_column_list, lead_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__lead_pass_through_columns') }}

    from {{ source('salesforce','lead') }}
    where coalesce(_fivetran_active, true)

)

select *
from final
where not coalesce(is_deleted, false)
