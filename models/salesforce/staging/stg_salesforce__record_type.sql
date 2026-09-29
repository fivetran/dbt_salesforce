--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

{% set record_type_column_list = get_record_type_columns() %}
{% set record_type_column_payload = normalize_column_payload(var('salesforce__record_type_column_payload', {})) %}

with final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(record_type_column_list, record_type_column_payload) }}

    from {{ source('salesforce','record_type') }}
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
