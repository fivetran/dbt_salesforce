{{
    config(
        enabled = var('salesforce__account_history_enabled', False),
        materialized = 'incremental',
        partition_by = {
            'field': 'date_day', 
            'data_type': 'date'
        } if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key = 'account_day_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks') else 'delete+insert',
        file_format = 'parquet',
        on_schema_change = 'fail'
    )
}}

with spine as (

    {% if execute %}
    {% if not var('account_history_start_date', None) or not var('account_history_end_date', None) 
       or not var('global_history_start_date', None) or not var('global_history_end_date', None) %}
        {% set date_query %} 
        select 
            greatest(min_date, '2016-01-01') as min_date,
            max_date
        from (
            select 
                min( _fivetran_start ) as min_date,
                {{ dbt.date_trunc('day', dbt.current_timestamp_backcompat()) }} as max_date
            from {{ source('salesforce_history', 'account') }}
            ) account_min_max
        {% endset %}

        {% set first_date = run_query(date_query).columns[0][0]|string %}
        {% set last_date = run_query(date_query).columns[1][0]|string %}
    {% endif %}

    {# If only compiling, creates range going back 1 year #}
    {% else %} 
        {% set first_date = dbt.dateadd("year", "-1", "current_date") %}
        {% set last_date = dbt.current_timestamp_backcompat() %}
    {% endif %}

    {# Prioritizes variables over calculated dates #}
    {% if var('account_history_start_date', []) or var('account_history_end_date', []) %}
        {% set first_date = var('account_history_start_date', calc_first_date)|string %}
        {% set last_date = var('account_history_end_date', calc_last_date)|string %}
    {% elif var('global_history_start_date', []) or var('global_history_end_date', []) %}
        {% set first_date = var('global_history_start_date', calc_first_date)|string %}
        {% set last_date = var('global_history_end_date', calc_last_date)|string %}
    {% endif %}

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date = "cast('" ~ first_date[0:10] ~ "'as date)",
        end_date = "cast('" ~ last_date[0:10] ~ "'as date)"
        )
    }}

    {% if is_incremental() %}
        where cast(date_day as date) >= (select max(date_day) from {{ this }})
    {% endif %}
),

account_history as (

    select *        
    from {{ var('account_history') }}
    {% if is_incremental() %}
        where _fivetran_start >= (select max(cast((_fivetran_start) as {{ dbt.type_timestamp() }})) from {{ this }} )
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
        cast(spine.date_day as date) as date_day,
        get_latest_daily_value.*,
        {{ dbt_utils.generate_surrogate_key(['spine.date_day','get_latest_daily_value.account_id']) }} as account_day_id
    from get_latest_daily_value
    join spine on get_latest_daily_value._fivetran_start <= cast(spine.date_day as {{ dbt.type_timestamp() }})
        and get_latest_daily_value._fivetran_end >= cast(spine.date_day as {{ dbt.type_timestamp() }})
)

select * 
from daily_history