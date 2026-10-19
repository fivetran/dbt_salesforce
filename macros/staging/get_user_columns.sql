{% macro get_user_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_active", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_id", "source_name": "AccountId", "datatype": dbt.type_string()},
    {"name": "alias", "source_name": "Alias", "datatype": dbt.type_string()},
    {"name": "city", "source_name": "City", "datatype": dbt.type_string()},
    {"name": "company_name", "source_name": "CompanyName", "datatype": dbt.type_string()},
    {"name": "contact_id", "source_name": "ContactId", "datatype": dbt.type_string()},
    {"name": "country", "source_name": "Country", "datatype": dbt.type_string()},
    {"name": "country_code", "source_name": "CountryCode", "datatype": dbt.type_string()},
    {"name": "department", "source_name": "Department", "datatype": dbt.type_string()},
    {"name": "email", "source_name": "Email", "datatype": dbt.type_string()},
    {"name": "first_name", "source_name": "FirstName", "datatype": dbt.type_string()},
    {"name": "id", "source_name": "Id", "datatype": dbt.type_string()},
    {"name": "individual_id", "source_name": "IndividualId", "datatype": dbt.type_string()},
    {"name": "is_active", "source_name": "IsActive", "datatype": "boolean"},
    {"name": "last_login_date", "source_name": "LastLoginDate", "datatype": dbt.type_timestamp()},
    {"name": "last_name", "source_name": "LastName", "datatype": dbt.type_string()},
    {"name": "last_referenced_date", "source_name": "LastReferencedDate", "datatype": dbt.type_timestamp()},
    {"name": "last_viewed_date", "source_name": "LastViewedDate", "datatype": dbt.type_timestamp()},
    {"name": "manager_id", "source_name": "ManagerId", "datatype": dbt.type_string()},
    {"name": "name", "source_name": "Name", "datatype": dbt.type_string()},
    {"name": "postal_code", "source_name": "PostalCode", "datatype": dbt.type_string()},
    {"name": "profile_id", "source_name": "ProfileId", "datatype": dbt.type_string()},
    {"name": "state", "source_name": "State", "datatype": dbt.type_string()},
    {"name": "state_code", "source_name": "StateCode", "datatype": dbt.type_string()},
    {"name": "street", "source_name": "Street", "datatype": dbt.type_string()},
    {"name": "title", "source_name": "Title", "datatype": dbt.type_string()},
    {"name": "user_role_id", "source_name": "UserRoleId", "datatype": dbt.type_string()},
    {"name": "user_type", "source_name": "UserType", "datatype": dbt.type_string()},
    {"name": "username", "source_name": "Username", "datatype": dbt.type_string()},
] %}


{{ fivetran_utils.add_pass_through_columns(columns, var('salesforce__user_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}