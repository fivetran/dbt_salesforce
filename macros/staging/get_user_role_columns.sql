{% macro get_user_role_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "developer_name", "source_name": "DeveloperName", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "opportunity_access_for_account_owner", "source_name": "OpportunityAccessForAccountOwner", "datatype": dbt.type_string()},
    {"name": "parent_role_id", "source_name": "ParentRoleId", "datatype": dbt.type_string()},
    {"name": "rollup_description", "source_name": "RollupDescription", "datatype": dbt.type_string()}
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__user_role_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}