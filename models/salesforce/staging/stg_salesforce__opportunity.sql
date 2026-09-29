{% set opportunity_column_list = get_opportunity_columns() %}
{% set opportunity_column_payload = normalize_column_payload(var('salesforce__opportunity_column_payload', {})) %}

with final as (

    select

        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        {{ apply_column_payload(opportunity_column_list, opportunity_column_payload) }}

        {{ fivetran_utils.fill_pass_through_columns('salesforce__opportunity_pass_through_columns') }}

    from {{ source('salesforce','opportunity') }}
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
