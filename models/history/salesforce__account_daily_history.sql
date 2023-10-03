{{ config(enabled=var('account_history_enabled', False)) }}

{{
    config(
        materialized='incremental',
        partition_by = {'field': 'date_day', 'data_type': 'date'}
            if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key='account_day_id',
        incremental_strategy = 'merge' if target.type not in ('snowflake', 'postgres', 'redshift') else 'delete+insert',
        file_format = 'delta'
    )
}}

with spine as (

    {% if execute %}
    {% if not var('salesforce_history_fivetran_start', None) or not var('salesforce_history_fivetran_end', None) %}
        {% set date_query %}
        select 
            min( _fivetran_start ) as min_date,
            {{ dbt.date_trunc('day', dbt.current_timestamp_backcompat()) }} as max_date
        from {{ source('salesforce_history', 'account') }}
        {% endset %}

        {% set calc_first_date = run_query(date_query).columns[0][0]|string %}
        {% set calc_last_date = run_query(date_query).columns[1][0]|string %}
    {% endif %}

    {# If only compiling, creates range going back 1 year #}
    {% else %} 
        {% set calc_first_date = dbt.dateadd("year", "-1", "current_date") %}
        {% set calc_last_date = dbt.current_timestamp_backcompat() %}
    {% endif %}

    {# Prioritizes variables over calculated dates #}
    {% set first_date = var('salesforce_history_fivetran_start', calc_first_date)|string %}
    {% set last_date = var('salesforce_history_fivetran_end', calc_last_date)|string %}

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date = "cast('" ~ first_date[0:10] ~ "'as date)",
        end_date = "cast('" ~ last_date[0:10] ~ "'as date)"
        )
    }}

    {% if is_incremental() %}
    where cast(date_day as date) >= (select max(date_day) from {{ this }} )
    {% endif %}
),

account_history as (

    select *,
        cast( {{ dbt.date_trunc('day', '_fivetran_start') }} as date) as start_day       
    from {{ var('account_history') }}

),

order_daily_values as (

    select 
        *,
        row_number() over (
            partition by start_day, account_id
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