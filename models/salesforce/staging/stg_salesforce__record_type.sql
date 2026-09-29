--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('record_type', get_record_type_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as record_type_id,
        cast(description as {{ dbt.type_string() }}) as record_type_description,
        cast(developer_name as {{ dbt.type_string() }}) as developer_name,
        cast(is_active as {{ "boolean" }}) as is_active,
        cast(name as {{ dbt.type_string() }}) as record_type_name,
        cast(namespace_prefix as {{ dbt.type_string() }}) as namespace_prefix,
        cast(sobject_type as {{ dbt.type_string() }}) as sobject_type

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
