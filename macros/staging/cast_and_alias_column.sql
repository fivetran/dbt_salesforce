{% macro cast_and_alias_column(
    column_key,
    column_dict,
    original_column_name=column_dict[column_key]["name"],
    datatype=column_dict[column_key]["datatype"],
    alias=column_dict[column_key]["alias"] | default(original_column_name)
    ) %}
{#
    Replaces `coalesce_rename` now that `fields` (via `apply_column_payload`) has already
    resolved each column to the one true source reference -- there's no second guessed
    spelling left to coalesce against, just a cast and an optional rename.
#}
cast({{ original_column_name }} as {{ datatype }}) as {{ alias }}
{%- endmacro %}
