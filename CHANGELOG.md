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
