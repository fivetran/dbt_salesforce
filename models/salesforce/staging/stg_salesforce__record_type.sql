--To disable this model, set the salesforce__record_type_enabled within your dbt_project.yml file to False.
{{ config(enabled=var('salesforce__record_type_enabled', True)) }}

{% set record_type_column_list = get_record_type_columns() -%}
{% set record_type_dict = column_list_to_dict(record_type_column_list) -%}
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
        {{ salesforce.cast_and_alias_column("id", record_type_dict, alias="record_type_id") }},
        {{ salesforce.cast_and_alias_column("description", record_type_dict, alias="record_type_description") }},
        {{ salesforce.cast_and_alias_column("developer_name", record_type_dict) }},
        {{ salesforce.cast_and_alias_column("is_active", record_type_dict) }},
        {{ salesforce.cast_and_alias_column("name", record_type_dict, alias="record_type_name") }},
        {{ salesforce.cast_and_alias_column("namespace_prefix", record_type_dict) }},
        {{ salesforce.cast_and_alias_column("sobject_type", record_type_dict) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
