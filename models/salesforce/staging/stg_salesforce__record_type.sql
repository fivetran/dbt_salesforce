--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

{% set record_type_column_list = get_record_type_columns() -%}
{% set record_type_relation = source('salesforce','record_type') %}
{% set record_type_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), record_type_relation.schema, record_type_relation.identifier) %}

with fields as (

    select

        {{
            apply_column_payload(record_type_column_list, record_type_column_payload)
        }}

    from {{ record_type_relation }}
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
