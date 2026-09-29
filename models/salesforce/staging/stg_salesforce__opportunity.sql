{% set opportunity_column_list = get_opportunity_columns() -%}
{% set opportunity_dict = column_list_to_dict(opportunity_column_list) -%}
{% set opportunity_relation = source('salesforce','opportunity') %}
{% set opportunity_column_payload = normalize_column_payload(var('salesforce__column_payload', {}), opportunity_relation.schema, opportunity_relation.identifier) %}

with fields as (

    select

        {{
            apply_column_payload(opportunity_column_list, opportunity_column_payload)
        }}

    from {{ opportunity_relation }}
), 

final as (
    
    select 
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ salesforce.cast_and_alias_column("account_id", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("amount", opportunity_dict, datatype=dbt.type_numeric()) }},
        {{ salesforce.cast_and_alias_column("campaign_id", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("close_date", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("created_date", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("description", opportunity_dict, alias="opportunity_description") }},
        {{ salesforce.cast_and_alias_column("expected_revenue", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("fiscal", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("fiscal_quarter", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("fiscal_year", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("forecast_category", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("forecast_category_name", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("has_open_activity", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("has_opportunity_line_item", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("has_overdue_task", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("id", opportunity_dict, alias="opportunity_id") }},
        {{ salesforce.cast_and_alias_column("is_closed", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("is_deleted", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("is_won", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("last_activity_date", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("last_referenced_date", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("last_viewed_date", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("lead_source", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("name", opportunity_dict, alias="opportunity_name") }},
        {{ salesforce.cast_and_alias_column("next_step", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("owner_id", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("probability", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("record_type_id", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("stage_name", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("synced_quote_id", opportunity_dict) }},
        {{ salesforce.cast_and_alias_column("type", opportunity_dict) }}
        
        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
), 

calculated as (
        
    select 
        *,
        created_date >= {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_created_this_month,
        created_date >= {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_created_this_quarter,
        {{ dbt.datediff(dbt.current_timestamp_backcompat(), 'created_date', 'day') }} as days_since_created,
        {{ dbt.datediff('close_date', 'created_date', 'day') }} as days_to_close,
        {{ dbt.date_trunc('month', 'close_date') }} = {{ dbt.date_trunc('month', dbt.current_timestamp_backcompat()) }} as is_closed_this_month,
        {{ dbt.date_trunc('quarter', 'close_date') }} = {{ dbt.date_trunc('quarter', dbt.current_timestamp_backcompat()) }} as is_closed_this_quarter
    from final
)

select * 
from calculated
where not coalesce(is_deleted, false)