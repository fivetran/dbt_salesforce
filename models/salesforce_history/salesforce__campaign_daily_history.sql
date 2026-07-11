{{
    config(
        enabled = var('salesforce__campaign_history_enabled', False),
        materialized = 'incremental',
        partition_by = {
            'field': 'date_day',
            'data_type': 'date'
        } if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key = 'campaign_day_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks') else 'delete+insert',
        file_format = 'delta',
        on_schema_change = 'fail'
    )
}}

{% set first_date = var('campaign_history_start_date', var('global_history_start_date', '2020-01-01')) %}

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date = "cast('" ~ first_date ~ "' as date)",
        end_date = "cast(current_date as date)"
        )
    }}
),

campaign_history as (

    select
        id as campaign_id,
        cast(_fivetran_start as {{ dbt.type_timestamp() }}) as _fivetran_start,
        cast(_fivetran_end as {{ dbt.type_timestamp() }}) as _fivetran_end,
        cast(_fivetran_start as date) as _fivetran_date,
        {{ dbt_utils.generate_surrogate_key(['id', '_fivetran_start']) }} as history_unique_key,
        {{ dbt_utils.star(from=source('salesforce_history','campaign'),
                        except=["id", "_fivetran_start", "_fivetran_end"]) }}

    from {{ source('salesforce_history','campaign') }}

    {% if is_incremental() %}
    where cast(_fivetran_start as date) >= (select max(cast((_fivetran_start) as date)) from {{ this }})
    {% else %}
    where cast(_fivetran_start as date) >= cast('{{ first_date }}' as date)
    {% endif %}
),

order_daily_values as (

    select
        *,
        row_number() over (
            partition by _fivetran_date, campaign_id
            order by _fivetran_start desc) as row_num
    from campaign_history
),

get_latest_daily_value as (

    select *
    from order_daily_values
    where row_num = 1
),

daily_history as (

    select
        {{ dbt_utils.generate_surrogate_key(['spine.date_day','get_latest_daily_value.campaign_id']) }} as campaign_day_id,
        cast(spine.date_day as date) as date_day,
        get_latest_daily_value.*
    from get_latest_daily_value
    join spine on get_latest_daily_value._fivetran_start <= cast(spine.date_day as {{ dbt.type_timestamp() }})
        and get_latest_daily_value._fivetran_end >= cast(spine.date_day as {{ dbt.type_timestamp() }})
)

select *
from daily_history
