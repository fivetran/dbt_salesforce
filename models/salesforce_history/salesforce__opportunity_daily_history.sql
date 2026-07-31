{{
    config(
        enabled = var('salesforce__opportunity_history_enabled', False),
        materialized = 'incremental',
        partition_by = {
            'field': 'date_day',
            'data_type': 'date'
        } if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key = 'opportunity_day_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks') else 'delete+insert',
        file_format = 'delta',
        on_schema_change = 'fail'
    )
}}

{% set first_date = var('opportunity_history_start_date', var('global_history_start_date', '2020-01-01')) %}

{% if is_incremental() %}
    {% set spine_start_query %}
        select coalesce(max(date_day), cast('{{ first_date[0:10] }}' as date)) as spine_start_date
        from {{ this }}
    {% endset %}
    {% set spine_start_date = (dbt_utils.get_single_value(spine_start_query) | string) %}
{% else %}
    {% set spine_start_date = first_date[0:10] %}
{% endif %}

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ spine_start_date ~ "' as date)",
        end_date="cast(current_date as date)"
        )
    }}
),

opportunity_history as (

    select
        id as opportunity_id,
        cast(_fivetran_start as {{ dbt.type_timestamp() }}) as _fivetran_start,
        cast(_fivetran_end as {{ dbt.type_timestamp() }}) as _fivetran_end,
        cast(_fivetran_start as date) as _fivetran_date,
        {{ dbt_utils.generate_surrogate_key(['id', '_fivetran_start']) }} as history_unique_key,
        {{ dbt_utils.star(from=source('salesforce_history', 'opportunity'),
                        except=["id", "_fivetran_start", "_fivetran_end"]) }}

    from {{ source('salesforce_history', 'opportunity') }}

    -- The shared boundary below drives both which spine dates get (re)generated and which source
    -- history records are pulled: any record still open or closed on/after that boundary could
    -- apply to a newly generated spine date, regardless of when it last changed.
    {% if is_incremental() %}
    where cast(_fivetran_end as date) >= cast('{{ spine_start_date }}' as date)
    {% else %}
    {% if var('global_history_start_date', []) or var('opportunity_history_start_date', []) %}
    where cast(_fivetran_start as date) >= cast('{{ first_date[0:10] }}' as date)
    {% endif %}
    {% endif %}
),

order_daily_values as (

    select
        *,
        row_number() over (
            partition by _fivetran_date, opportunity_id
            order by _fivetran_start desc) as row_num
    from opportunity_history
),

get_latest_daily_value as (

    select *
    from order_daily_values
    where row_num = 1
),

daily_history as (

    select
        {{ dbt_utils.generate_surrogate_key(['spine.date_day','get_latest_daily_value.opportunity_id']) }} as opportunity_day_id,
        cast(spine.date_day as date) as date_day,
        get_latest_daily_value.*
    from get_latest_daily_value
    join spine on get_latest_daily_value._fivetran_start <= cast(spine.date_day as {{ dbt.type_timestamp() }})
        and get_latest_daily_value._fivetran_end >= cast(spine.date_day as {{ dbt.type_timestamp() }})
)

select *
from daily_history
