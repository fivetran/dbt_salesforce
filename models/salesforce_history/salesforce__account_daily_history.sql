{{
    config(
        enabled = var('salesforce__account_history_enabled', False),
        materialized = 'incremental',
        partition_by = {
            'field': 'date_day',
            'data_type': 'date'
        } if target.type not in ('spark', 'databricks', 'duckdb') else ['date_day'],
        unique_key = 'account_day_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks') else 'delete+insert',
        file_format = 'delta',
        on_schema_change = 'fail'
    )
}}

{% set first_date = var('account_history_start_date', var('global_history_start_date', '2020-01-01')) %}

{% set spine_start_date = salesforce.history_spine_start_date(first_date) %}

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=spine_start_date,
        end_date="cast(current_date as date)"
        )
    }}
),

account_history as (

    select
        id as account_id,
        cast(_fivetran_start as {{ dbt.type_timestamp() }}) as _fivetran_start,
        cast(_fivetran_end as {{ dbt.type_timestamp() }}) as _fivetran_end,
        cast(_fivetran_start as date) as _fivetran_date,
        {{ dbt_utils.generate_surrogate_key(['id', '_fivetran_start']) }} as history_unique_key,
        {{ dbt_utils.star(from=source('salesforce_history', 'account'),
                        except=["id", "_fivetran_start", "_fivetran_end"]) }}

    from {{ source('salesforce_history', 'account') }}

    -- The shared boundary below drives both which spine dates get (re)generated and which source
    -- history records are pulled: any record still open or closed on/after that boundary could
    -- apply to a newly generated spine date, regardless of when it last changed.
    {% if is_incremental() %}
    where cast(_fivetran_end as date) >= {{ spine_start_date }}
    {% else %}
    {% if var('global_history_start_date', []) != [] or var('account_history_start_date', []) != [] %}
    where cast(_fivetran_start as date) >= cast('{{ first_date[0:10] }}' as date)
    {% endif %}
    {% endif %}
),

order_daily_values as (

    select
        *,
        row_number() over (
            partition by _fivetran_date, account_id
            order by _fivetran_start desc) as row_num
    from account_history
),

get_latest_daily_value as (

    select *
    from order_daily_values
    where row_num = 1
),

daily_history as (

    select
        {{ dbt_utils.generate_surrogate_key(['spine.date_day','get_latest_daily_value.account_id']) }} as account_day_id,
        cast(spine.date_day as date) as date_day,
        get_latest_daily_value.*
    from get_latest_daily_value
    join spine on get_latest_daily_value._fivetran_start <= cast(spine.date_day as {{ dbt.type_timestamp() }})
        and get_latest_daily_value._fivetran_end >= cast(spine.date_day as {{ dbt.type_timestamp() }})
)

select *
from daily_history
