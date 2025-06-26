# dbt_salesforce v1.3.0

[PR #64](https://github.com/fivetran/dbt_salesforce/pull/64) includes the following updates:

## Breaking Change for dbt Core < 1.9.6

> *Note: This is not relevant to Fivetran Quickstart users.*

Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core ([Salesforce Source v1.2.0](https://github.com/fivetran/dbt_salesforce_source/releases/tag/v1.2.0)). This will resolve the following deprecation warning that users running dbt >= 1.9.6 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `salesforce` in file
`models/src_salesforce.yml`. The `freshness` top-level property should be moved
into the `config` of `salesforce`.
```

**IMPORTANT:** Users running dbt Core < 1.9.6 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.6 and want to continue running Salesforce freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.6
  2. Do not upgrade your installed version of the `salesforce` package. Pin your dependency on v1.2.1 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's `salesforce` source and apply freshness via the previous release top-level property route. This will require you to copy and paste the entirety of the previous release `src_salesforce.yml` file and add an `overrides: salesforce_source` property.

## Under the Hood
- Updates to ensure integration tests use latest version of dbt.

# dbt_salesforce v1.2.1
This release includes the following updates:

## Under the Hood
- Prepends `materialized` configs in the package's `dbt_project.yml` file with `+` to improve compatibility with the newer versions of dbt-core starting with v1.10.0. ([PR #62](https://github.com/fivetran/dbt_salesforce/pull/62))
- Updates the package maintainer pull request template. ([PR #63](https://github.com/fivetran/dbt_salesforce/pull/63))

## Contributors
- [@b-per](https://github.com/b-per) ([PR #62](https://github.com/fivetran/dbt_salesforce/pull/62))

# dbt_salesforce v1.2.0
This release includes the following updates:

## Quickstart Fixes
- Fixed casing syntax in `quickstart.yml` to match the default options in the Salesforce connector schema tab. Source tables are now in upper case, and snake casing is updated to camel casing. ([#61](https://github.com/fivetran/dbt_salesforce/pull/61))

## Documentation
- Added Quickstart model counts to README. ([#59](https://github.com/fivetran/dbt_salesforce/pull/59))
- Corrected references to connectors and connections in the README. ([#59](https://github.com/fivetran/dbt_salesforce/pull/59))
- Moved badges at top of the README below the H1 header to be consistent with popular README formats. ([#61](https://github.com/fivetran/dbt_salesforce/pull/61))

# dbt_salesforce v1.1.1
[PR #56](https://github.com/fivetran/dbt_salesforce/pull/56) includes the following updates:
## Bugfix
- Updated the logic for model `int_salesforce__date_spine` to reference the `stg_*` staging models instead of the source tables.
  - This was necessary since the staging models account for multiple spellings of column names while the source tables do not.

## Under the hood
- Added `--depends_on:` comments to `int_salesforce__date_spine` to prevent errors during `dbt run`.
- Added `flags.WHICH in ('run', 'build')` as a condition in `int_salesforce__date_spine` to prevent call statements from querying the staging models during a `dbt compile`.

# dbt_salesforce v1.1.0
[PR #55](https://github.com/fivetran/dbt_salesforce/pull/55) includes the following updates:

## 🚨 Breaking Change 🚨
- This change is made breaking due to changes made in the source package. See the [v1.1.0 dbt_salesforce_source release notes](https://github.com/fivetran/dbt_salesforce_source/releases/tag/v1.1.0) for more details.
- Added logic to support user-specified scenarios where the Fivetran Salesforce connector syncs column names using the original Salesforce API naming convention. For example, while Fivetran typically provides the column as `created_date`, some users might choose to receive it as `CreatedDate` according to the API naming. This update ensures the package is automatically compatible with both naming conventions.
  - Specifically, the package now performs a COALESCE, preferring the original Salesforce API naming. If the original naming is not present, the Fivetran version is used instead.
  - Renamed columns are now explicitly cast to prevent conflicts during the COALESCE. 
  - ❗This change is considered breaking since the resulting column types may differ from prior versions of this package.

## Under the hood
- Added validation test to ensure the final column names generated before and after this update remain the same.

# dbt_salesforce v1.0.2
[PR #52](https://github.com/fivetran/dbt_salesforce/pull/52) includes the following updates:

## Bug fixes
- Updated model `int_salesforce__date_spine` to accommodate when the Salesforce `lead` object exists but has no records. In this case, the model now defaults to a range of one-month from the current date.

## Under the hood
- Updated structure of model `int_salesforce__date_spine` for improved performance and maintainability.
- Updated maintainer pull request template.

# dbt_salesforce v1.0.1
[PR #48](https://github.com/fivetran/dbt_salesforce/pull/48) includes the following updates:

## Bug Fix
- Aligns the `last_date_query` logic in the `int_salesforce__date_spine` model with the `first_date_query` logic. This ensures that users with empty `opportunity` tables will have a valid end-date (based on `lead` instead of `opportunity`) for the `salesforce__daily_activity` end model.
  - Also adds coalesce-logic to `int_salesforce__date_spine` to ensure a succesful run without `lead` data.

## Documentation
- Documents how users without an `opportunity` table can still have the package run successfully for them. See [README](https://github.com/fivetran/dbt_salesforce?tab=readme-ov-file#working-without-an-opportunity-table) for details.

## Under the Hood
- Included auto-releaser GitHub Actions workflow to automate future releases.

# 🚨 Notice for Quickstart Data Model Users Only 🚨
Please note that this data model will now create a new transformation for **all** your Salesforce objects (tables) to replicate and include the relevant Salesforce formula fields. With the addition of formula fields, your transformation schema will change to <connector_schema> + `_quickstart`, rather than inheriting the schema from your connector. Please make sure you adjust downstream queries accordingly. If you wish to disable any of these new transformations you may remove them within the UI.

If you are not already a Quickstart Data Model user, you can find out more information [here](https://fivetran.com/docs/transformations/quickstart)!

# dbt_salesforce v1.0.0 

**📣 THIS IS A MAJOR PACKAGE RELEASE! 📣** More details below. 

[PR #45](https://github.com/fivetran/dbt_salesforce/pull/45) includes the following updates:

## 🚨 Breaking Change 🚨
- We have removed all `tmp` models in the dependent `dbt_salesforce_source` package, and will use the `fivetran_utils.fill_staging_column` macro to compare directly to our source models in your schemas.

## 🚀 Feature Updates 🚀 
- We have added daily history mode models in the [`models/salesforce_history`](https://github.com/fivetran/dbt_salesforce/tree/main/models/salesforce_history) folder [based off of Fivetran's history mode feature](https://fivetran.com/docs/core-concepts/sync-modes/history-mode), pulling from source models in `dbt_salesforce_source`. This will allow customers to utilize the Fivetran history mode feature, which records every version of each record in the source table from the moment this mode is activated in the equivalent tables.

- **IMPORTANT: All fields in your Salesforce history mode connector that are being synced are being included in the end models**. To change which fields are brought in via end models, you will need to update the fields you are bringing in via your history mode connector in Fivetran and then run a `dbt run --full-refresh`. [See the DECISIONLOG for more details](https://github.com/fivetran/dbt_salesforce_source/blob/main/DECISIONLOG.md).

- Below are the new models included in this update:

|**Model added**|**Description** 
-----|----- 
| [salesforce__account_daily_history](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__account_daily_history) | Each record is a daily record in an account, starting with its first active date and updating up toward either the current date (if still active) or its last active date.  
| [salesforce__contact_daily_history](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__contact_daily_history) |  Each record is a daily record in an contact, starting with its first active date and updating up toward either the current date (if still active) or its last active date.
| [salesforce__opportunity_daily_history](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__opportunity_daily_history) | Each record is a daily record in an opportunity, starting with its first active date and updating up toward either the current date (if still active) or its last active date. 

- All history models are incremental due to the volume of data being ingested. 

- We support the option to pull from both your standard Salesforce and History Mode connectors simultaneously from their specific database/schemas.  We also support pulling from just your History Mode connector on its own and bypassing the standard connector on its own. [See more detailed instructions for configuring your history mode database and schema variables in the README](https://github.com/fivetran/dbt_salesforce/blob/main/README.md#configuring-your-salesforce-history-mode-database-and-schema-variables).

- These models are disabled by default due to their size, so you will need to set the below variable configurations for each of the individual models you want to utilize in your `dbt_project.yml`. [More details are available in the README](https://github.com/fivetran/dbt_salesforce/blob/main/README.md#enabling-salesforce-history-mode-models).

```yml 
vars:
  salesforce__[history_model]_enabled: true ##Ex: salesforce__account_history_enabled: true          
```

- We've added variable configuration that will allow you to filter the history start and end dates to filter down the data you ingest in each model. See the `Setting the date range for the Salesforce Daily History models` [section in the README](https://github.com/fivetran/dbt_salesforce/blob/main/README.md#filter-your-salesforce-history-mode-models-with-field-variable-conditionals) for more details. 

## 🔎 Under The Hood 🔎
- We have deprecated the `using_[source]_history_mode_active_records` variables. The introduction of the new history mode capabilities in this package made these variables redundant.  

# dbt_salesforce v0.9.3
## 🪲 Bug Fix ⚒️
[PR #44](https://github.com/fivetran/dbt_salesforce/pull/44) introduces the following update:

- Updated the `first_date_query` logic in `int_salesforce__date_spine` to select first date from the minimum `created_date` on the `opportunity` source when the `lead` source is not available.

# dbt_salesforce v0.9.2
## Documentation and Notice Updates
[PR #42](https://github.com/fivetran/dbt_salesforce/pull/42) includes the following update:

- Notices were added to both the top of the CHANGELOG and within the README to alert users of the Quickstart Data Model that Salesforce formulas will be replicated in the Fivetran transformation. For non Quickstart Data Model users there will be no change following this update. 
  - If you would like to learn more about the Quickstart Data Model for Salesforce you can find more information [here](https://fivetran.com/docs/transformations/quickstart). 

# dbt_salesforce v0.9.1
## Bug Fixes
[PR #40](https://github.com/fivetran/dbt_salesforce/pull/40) includes the following bug fixes.
- The `salesforce__opportunity_pass_through_columns` passthrough variable config has been removed from the `salesforce__opportunity_enhanced` to ensure duplicate columns are not introduced when leveraging the opportunity passthrough functionality.
  - When using the `salesforce__opportunity_pass_through_columns` variable, you will still see the results populated in the `salesforce__opportunity_enhanced`. The fields are already introduced via the `opportunity.*` in the select statement. 

# dbt_salesforce v0.9.0

## 🚨 Breaking Changes 🚨:
[PR #38](https://github.com/fivetran/dbt_salesforce/pull/38) includes the following breaking changes:

- Updates the old passthrough column methodology to allow for aliasing and/or transformations of any field names brought in. This is useful, for example, if you wish to bring in fields across different Salesforce objects that may have the same names and wish to alias them to avoid confusion, particularly if any of the objects are joined together.

- Additionally, in the `salesforce__opportunity_enhanced` model, the old `opportunity_enhanced_pass_through_columns` variable has been replaced with the existing variables from the staging models (see below). This is because we updated the `salesforce__opportunity_enhanced` model with regards to how custom fields passed through from the `user` table are dealt with. Since the `user` model is joined in two times, once as information about an opportunity owner and the other about an opportunity manager, to avoid ambiguity, custom fields passed through from the user table will be suffixed based on whether it belongs to a user who is an `_owner` or a `_manager`. 

- Finally, we have added the `salesforce__` prefix to all the passthrough variables:

|**Old**|**New**
-----|-----
| account_pass_through_columns | salesforce__account_pass_through_columns
| contact_pass_through_columns | salesforce__contact_pass_through_columns
| event_pass_through_columns | salesforce__event_pass_through_columns
| lead_pass_through_columns | salesforce__lead_pass_through_columns
| opportunity_pass_through_columns | salesforce__opportunity_pass_through_columns
| opportunity_line_item_pass_through_columns   | salesforce__opportunity_line_item_pass_through_columns
| order_pass_through_columns | salesforce__order_pass_through_columns
| product_2_pass_through_columns | salesforce__product_2_pass_through_columns
| task_pass_through_columns | salesforce__task_pass_through_columns
| user_role_pass_through_columns | salesforce__user_role_pass_through_columns
| user_pass_through_columns | salesforce__user_pass_through_columns

 ## Under the Hood:

- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job.
- Updated the pull request [templates](/.github).


# dbt_salesforce v0.8.0

## 🚨 Breaking Changes 🚨:
[PR #36](https://github.com/fivetran/dbt_salesforce/pull/36) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- Dependencies on `fivetran/fivetran_utils` have been upgraded, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

# dbt_salesforce v0.7.2
PR [#35](https://github.com/fivetran/dbt_salesforce/pull/35) incorporates the following updates:
## Bug Fixes
  - Add all model variables to the README "Disabling Models" section
  - Remove model variables from this package's `dbt_project.yml` to avoid potential conflict with a user's settings.
  

# dbt_salesforce v0.7.1
## Features
  - Resolving bug in `salesforce__contact_enhanced` when using user passthrough columns.
  - Resolving bug in `salesforce__opportunity_line_item_enhanced` when using user passthrough columns.  

## Contributors
- [@calder-holt](https://github.com/calder-holt) ([#32](https://github.com/fivetran/dbt_salesforce/pull/32))

# dbt_salesforce v0.7.0
🎉 Salesforce Package Updates 🎉

PR [#30](https://github.com/fivetran/dbt_salesforce/pull/30) includes various updates to the Salesforce package! To improve its utility, the changes include the following:
## Features
  - Creating a new `salesforce__contact_enhanced`, `salesforce__daily_activity`, and `salesforce__opportunity_line_item_enhanced` model as well as updating the `salesforce__opportunity_enhanced` model.
  - Allowing [formula fields](https://github.com/fivetran/dbt_salesforce#adding-formula-fields-as-pass-through-columns) to be added as passthrough columns. We added integration with the Salesforce Formula package by embedding the macro outputs as part of our staging models so that your custom formula fields can be included.
  - Add [enable/disable configs](https://github.com/fivetran/dbt_salesforce#disabling-models) for tables that you may not be syncing
  - Add [identifier variables](https://github.com/fivetran/dbt_salesforce#change-the-source-table-references) in case a source table has a different name from the default
  - Add [history mode configs](https://github.com/fivetran/dbt_salesforce#salesforce-history-mode) for the new source tables
  - Add [passthrough column configs](https://github.com/fivetran/dbt_salesforce#adding-passthrough-columns) for additional columns that you wish to populate in the end models



# dbt_salesforce v0.6.0
## Features
- Updated package to align with most recent standards:
  - Updated formatting in our `sql` files.
  - The README has been updated to reflect our rehaul of our documentation style to make it more straightforward. 
([#28](https://github.com/fivetran/dbt_salesforce/pull/28))
# dbt_salesforce v0.5.1
## Features
- Support for Databricks compatibility! ([#24](https://github.com/fivetran/dbt_salesforce/pull/24))
- Added feature to disable `user_role` table if not being synced. This will build the models while ignoring metrics depending on the `user_role` table.

# dbt_salesforce v0.5.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_salesforce_source`. Additionally, the latest `dbt_salesforce_source` package has a dependency on the latest `dbt_fivetran_utils`. Further, the latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

# dbt_salesforce v0.1.0 -> v0.4.0
Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!
