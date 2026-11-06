--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

{%- set source_table = {'source_name': 'salesforce', 'table_name': 'record_type'} -%}

with fields as (

    {{ salesforce.resolve_source_columns(staging_columns=salesforce.get_record_type_columns(), **source_table) }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(id as {{ dbt.type_string() }}) as record_type_id,
        description as record_type_description,
        developer_name,
        is_active,
        name as record_type_name,
        namespace_prefix,
        sobject_type

    from fields
    where {{ salesforce.sync_mode_filter(**source_table) }}
)

select *
from final
