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

with date_spine as (
    
    select 
        account_id,
        {{ dbt.date_trunc('day', 'date_day') }} as date_day
    from {{ ref('int_salesforce__account_history_spine') }}


    {% if is_incremental() %}
    where date_day >= (select max(date_day) from {{ this }} )
    {% endif %}

),

account_history as (

    select *
    from {{ var('account_history') }}   
)


select * 
from date_spine
inner join account_history 
  on date_spine.account_id = account_history.account_id
  and date_spine.date_day >= account_history._fivetran_start
  