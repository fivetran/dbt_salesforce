{{
    config(
        materialized='incremental',
        partition_by = {'field': 'date_day', 'data_type': 'date'}
            if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key='opportunity_day_id',
        incremental_strategy = 'merge' if target.type not in ('snowflake', 'postgres', 'redshift') else 'delete+insert',
        file_format = 'delta'
    )
}}

with spine as (

    {% if execute %}
    {% set first_date_query %}
    -- start at the first created history start date
        select  min( _fivetran_start ) as min_date from {{ source('salesforce_history', 'opportunity') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
    {% else %} {% set first_date = "2016-01-01" %}
    {% endif %}

    select *
    from (
        {{ 
            dbt_utils.date_spine(
                datepart = "day",
                start_date = "cast('" ~ first_date[0:10] ~ "'as date)",
                end_date = dbt.dateadd("day", -1, dbt.current_timestamp_in_utc_backcompat())
            )
        }}
    ) as date_spine


    {% if is_incremental() %}
    where cast( date_day as date) >= (select min(_fivetran_start) from {{ this }} )
    {% endif %}

),


opportunity_history as  (

    select *
    from {{ var('opportunity_history') }}   
),

opportunity_dates as (

    select 
        opportunity_history.opportunity_id,
        opportunity_history._fivetran_start
    from opportunity_history 
),

opportunity_spine as (

    select 
        cast{{ dbt.date_trunc('day', spine.date_day)}} as date_day,
        opportunity_dates.account_id
    from spine
    join opportunity_dates on
        opportunity_dates._fivetran_start <= spine.date_day
),

surrogate_key as (

    select
        date_day,
        opportunity_id,
        {{ dbt_utils.generate_surrogate_key(['date_day','account_id']) }} as account_day_id

    from opportunity_spine
    
    where date_day <= cast( {{ dbt.date_trunc('day', dbt.current_timestamp_in_utc_backcompat()) }} as date)
)

select *
from surrogate_key