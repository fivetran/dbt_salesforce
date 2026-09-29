--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

with fields as (

    {{ salesforce.select_payload_fields('record_type', get_record_type_columns()) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        id as record_type_id,
        description as record_type_description,
        developer_name,
        is_active,
        name as record_type_name,
        namespace_prefix,
        sobject_type

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
