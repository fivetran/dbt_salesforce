--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

{% set record_type_column_list = get_record_type_columns() -%}
{% set record_type_dict = column_list_to_dict(record_type_column_list) -%}

with fields as (

    select

        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('salesforce','record_type')),
                staging_columns=record_type_column_list
            )
        }}

    from {{ source('salesforce','record_type') }}
),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.coalesce_rename("description", record_type_dict, alias="record_type_description") }},
        {{ salesforce.coalesce_rename("developer_name", record_type_dict) }},
        {{ salesforce.coalesce_rename("id", record_type_dict, alias="record_type_id") }},
        {{ salesforce.coalesce_rename("is_active", record_type_dict) }},
        {{ salesforce.coalesce_rename("name", record_type_dict, alias="record_type_name") }},
        {{ salesforce.coalesce_rename("namespace_prefix", record_type_dict) }},
        {{ salesforce.coalesce_rename("sobject_type", record_type_dict) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
