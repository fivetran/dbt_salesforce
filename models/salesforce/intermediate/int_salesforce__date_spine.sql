
with spine as (

    {% if execute %}
    {% set first_date_query %}
        {% if var('salesforce__lead_enabled', True) %}
            select  min( created_date ) as min_date from {{ source('salesforce', 'lead') }}
        {% else %}
            select  coalesce(min( created_date ), '2015-01-01') as min_date from {{ source('salesforce', 'opportunity') }}
        {% endif %}   

    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
        {% if target.type == 'postgres' %}
            {% set first_date_adjust = "cast('" ~ first_date[0:10] ~ "' as date)" %}

        {% else %}
            {% set first_date_adjust = "'" ~ first_date[0:10] ~ "'" %}

        {% endif %}

    {% else %} {% set first_date_adjust = "'2015-01-01'" %}
    {% endif %}

    {% if execute %}
    {% set last_date_query %}
        {% if var('salesforce__lead_enabled', True) %}
            select  max( created_date ) as max_date from {{ source('salesforce', 'lead') }}
        {% else %}
        select  coalesce(max( created_date ), '2024-01-01') as max_date from {{ source('salesforce', 'opportunity') }}
        {% endif %}

    {% endset %}

    {% set current_date_query %}
        select current_date
    {% endset %}

    {% if run_query(current_date_query).columns[0][0]|string < run_query(last_date_query).columns[0][0]|string %}

    {% set last_date = run_query(last_date_query).columns[0][0]|string %}

    {% else %} {% set last_date = run_query(current_date_query).columns[0][0]|string %}
    {% endif %}
        
    {% if target.type == 'postgres' %}
        {% set last_date_adjust = "cast('" ~ last_date[0:10] ~ "' as date)" %}

    {% else %}
        {% set last_date_adjust = "'" ~ last_date[0:10] ~ "'" %}

    {% endif %}
    {% endif %}

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=first_date_adjust,
        end_date=dbt.dateadd("day", 1, last_date_adjust)
        )
    }}
)

select 

distinct(date_day)

from spine