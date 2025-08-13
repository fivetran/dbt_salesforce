{% macro coalesce_rename(
    column_key,
    column_dict,
    original_column_name=column_dict[column_key]["name"],
    datatype=column_dict[column_key]["datatype"],
    alias=column_dict[column_key]["alias"] | default(original_column_name),
    renamed_column_name=column_dict[column_key]["renamed_column_name"]
    ) %}

{#
    This macro is the final step in a workflow applied across models. It accommodates Fivetran connectors that retain Salesforce's original field naming conventions, which are camelCase instead of snake_case.

    Overview:
    1. `get_*_columns`: Creates list of snake_case columns for a given source table.  
        1a. `add_renamed_columns`: Appends camelCase spellings of columns to the list.  
        1b. `add_pass_through_columns`: Appends columns specified in the passthrough variable to the list.  
    2. `column_list_to_dict`: Converts the list of columns generated in Step 1 into a dictionary, simplifying subsequent operations.  
    3. `fill_staging_columns`: Ensures all columns from Step 1 are present in the source table by filling `null` values for any missing columns. For columns with multiple spellings, a `null` column is created for the unused spelling.  
    4. `coalesce_rename`: Uses the dictionary from `column_list_to_dict` to coalesce a column with its renamed counterpart. This step generates the final column and supports custom arguments for renamed spelling, data type, and alias to override default values.  
#}

{%- if original_column_name|lower == renamed_column_name|lower %}
    cast({{ renamed_column_name }} as {{ datatype }}) as {{ alias }}

{%- else %}
    coalesce(cast({{ renamed_column_name }} as {{ datatype }}),
        cast({{ original_column_name }} as {{ datatype }}))
        as {{ alias }}

{%- endif %}
{%- endmacro %}