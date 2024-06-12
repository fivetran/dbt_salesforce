with spine as (

    {% if execute %}

    {%- set first_date_query %}
        select 
            coalesce(
                min(cast(created_date as date)), 
                cast({{ dbt.dateadd("month", -1, "current_date") }} as date)
                ) as min_date
        {% if var('salesforce__lead_enabled', True) %}
            from {{ source('salesforce', 'lead') }}
        {% else %}
            from {{ source('salesforce', 'opportunity') }}
        {% endif %}  
    {% endset -%}

    {%- set first_date = dbt_utils.get_single_value(first_date_query) %}

    {% set last_date_query %}
        select 
            coalesce(
                greatest(max(cast(created_date as date)), cast(current_date as date)),
                cast(current_date as date)
                ) as max_date
        {% if var('salesforce__lead_enabled', True) %}
            from {{ source('salesforce', 'lead') }}
        {% else %}
            from {{ source('salesforce', 'opportunity') }}
        {% endif %}  
    {% endset -%}

    {%- set last_date = dbt_utils.get_single_value(last_date_query) %}

    {% else %}

    {% set first_date = 'dbt.dateadd("month", -1, "current_date")' %}
    {% set last_date = 'dbt.current_timestamp_backcompat()' %}

    {% endif %}

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ first_date ~ "' as date)",
        end_date=dbt.dateadd("day", 1, "cast('" ~ last_date  ~ "' as date)")
        )
    }}
)

select * 
from spine