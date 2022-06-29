
<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_salesforce/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="Fivetran-Release"
        href="https://fivetran.com/docs/getting-started/core-concepts#releasephases">
        <img src="https://img.shields.io/badge/dbt_core-version_>=1.0.0_<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Salesforce Modeling dbt Package ([Docs](https://fivetran.github.io/dbt_salesforce/))

# 📣 What does this dbt package do?
- Produces modeled tables that leverage Salesforce data from [Fivetran's connector](https://fivetran.com/docs/applications/salesforce) in the format described by [this ERD](https://fivetran.com/docs/applications/salesforce#schema) and builds off the output of our [Salesforce source package](https://github.com/fivetran/dbt_salesforce_source).

- This package enables users to:
  - Understand the performance of your opportunities
  - Understand what is going on in your sales funnel and 
  - Drill into how the members of your sales team are performing
  - Have a daily summary of sales activities 
  - Access an enhanced contact list

This package also generates a comprehensive data dictionary of your source and modeled Salesforce data via the [dbt docs site](https://fivetran.github.io/dbt_salesforce/)
You can also refer to the table below for a detailed view of all models materialized by default within this package.

|**model**|**description**
-----|-----
| [salesforce_manager_performance](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__manager_performance)     |Each record represents a manager, enriched with data about their team's pipeline, bookings, losses, and win percentages.
| [salesforce_owner_performance](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__owner_performance)         |Each record represents an individual member of the sales team, enriched with data about their pipeline, bookings, losses, and win percentages.
| [salesforce_sales_snapshot](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__sales_snapshot)               |A single row snapshot that provides various metrics about your sales funnel.
| [salesforce__opportunity_enhanced](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__opportunity_enhanced)  |Each record represents an opportunity, enriched with related data about the account and opportunity owner.
| [salesforce__contact_enhanced](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__contact_enhanced)  |Each record represents a contact with additional account and owner information.
| [salesforce__daily_activity](https://fivetran.github.io/dbt_salesforce/#!/model/model.salesforce.salesforce__daily_activity)  |Each record represents a daily summary of the number of sales activities, for example tasks and opportunities closed.

# 🤔 Who is the target user of this dbt package?
- You use Fivetran's [Salesforce connector](https://fivetran.com/docs/applications/salesforce)
- You use dbt
- You want a staging layer that cleans, tests, and prepares your Salesforce data for analysis as well as leverage the analysis ready models outlined above.
# 🎯 How do I use the dbt package?
To effectively install this package and leverage the pre-made models, you will follow the below steps:
## Step 1: Pre-Requisites
You will need to ensure you have the following before leveraging the dbt package.
- **Connector**: Have the Fivetran Salesforce connector syncing data into your warehouse. 
- **Database support**: This package has been tested on **BigQuery**, **Snowflake**, **Redshift**, **Databricks**, and **Postgres**. Ensure you are using one of these supported databases.
  - If you are using Databricks you'll need to add the below to your `dbt_project.yml`. 

```yml
# dbt_project.yml

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```
- **dbt Version**: This dbt package requires you have a functional dbt project that utilizes a dbt version within the respective range `>=1.0.0, <2.0.0`.
## Step 2: Installing the Package
Include the following salesforce_source package version in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/salesforce
    version: [">=1.0.0", "<2.0.0"]
```
## Step 3: Configure Your Variables
### Database and Schema Variables
By default, this package will run using your target database and the `salesforce` schema. If this is not where your Salesforce data is, add the following configuration to your root `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
    salesforce_database: your_database_name    
    salesforce_schema: your_schema_name
    salesforce__<default_source_table_name>_identifier: your_table_name
```
### Adding Passthrough Columns
This package allows users to add additional columns to the `opportunity enhanced` model and `contact enhanced` model. Columns passed through must be present in the downstream source account, contact, or user table. If you want to include a column from the user table, you must specify if you want it to be a field related to the opportunity_manager or opportunity_owner.

```yml
# dbt_project.yml

...
vars:
  opportunity_enhanced_pass_through_columns: [account_custom_field_1, account_custom_field_2, opportunity_manager.user_custom_column]
  account_pass_through_columns: [account_custom_field_1, account_custom_field_2]
  user_pass_through_columns: [user_custom_column_1,user_custom_column_2]
  contact_pass_through_columns: [contact_custom_field_1, contact_custom_field_2]
```

### Salesforce History Mode
If you have Salesforce [History Mode](https://fivetran.com/docs/getting-started/feature/history-mode) enabled for your connector, you will want to add and set the desired `using_[table]_history_mode_active_records` variable(s) as `true` to filter for only active records as the package is designed for non-historical data. These variables are disabled by default. 
```yml
# dbt_project.yml

...
vars:
  using_account_history_mode_active_records: true      # false by default. Only use if you have history mode enabled.
  using_opportunity_history_mode_active_records: true  # false by default. Only use if you have history mode enabled.
  using_user_role_history_mode_active_records: true    # false by default. Only use if you have history mode enabled.
  using_user_history_mode_active_records: true         # false by default. Only use if you have history mode enabled.
  using_contact_history_mode_active_records: true      # false by default. Only use if you have history mode enabled.
  using_lead_history_mode_active_records: true         # false by default. Only use if you have history mode enabled.
  using_task_history_mode_active_records: true         # false by default. Only use if you have history mode enabled.
  using_event_history_mode_active_records: true        # false by default. Only use if you have history mode enabled.
  using_product_2_history_mode_active_records: true    # false by default. Only use if you have history mode enabled.
  using_order_history_mode_active_records: true        # false by default. Only use if you have history mode enabled.
  using_opportunity_line_item_history_mode_active_records: true       # false by default. Only use if you have history mode enabled.
```
### Disabling Models
Your connector may not be syncing all tabes that this package references. This might be because you are excluding those tables. If you are not using those tables, you can disable the corresponding functionality in the package by specifying the variable in your `dbt_project.yml`. The metrics from the disabled tables will not populate in downstream models. By default, all packages are assumed to be true. You only have to add variables for tables you want to disable, like so:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  salesforce__user_role_enabled: false # Disable if you do not have the user_role table

```
## Changing Source Tables
Source tables are referenced using default names. In the event you wish to reference another table name, the `identifier` variable enables that flexibility. Add the following configuration to your root `dbt_project.yml` file to take advantage of this feature:
```yml
# dbt_project.yml
...
config-version: 2
vars:
    <package_name>__<default_source_table_name>_identifier: your_table_name
```
## (Optional) Step 5: Orchestrate your package models with Fivetran
Fivetran offers the ability for you to orchestrate your dbt project through the [Fivetran Transformations for dbt Core](https://fivetran.com/docs/transformations/dbt) product. Refer to the linked docs for more information on how to setup your project for orchestration through Fivetran. 

# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. For more information on the below packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> **If you have any of these dependent packages in your own `packages.yml` I highly recommend you remove them to ensure there are no package version conflicts.**
```yml
packages:
    - package: fivetran/salesforce_source
      version: [">=1.0.0", "<2.0.0"]
    - package: fivetran/fivetran_utils
      version: [">=0.3.0", "<0.4.0"]
    - package: dbt-labs/dbt_utils
      version: [">=0.8.0", "<0.9.0"]
```
# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package **only** maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/salesforce/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_salesforce/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.
## Contributions
These dbt packages are developed by a small team of analytics engineers at Fivetran. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package!

# 🏪 Are there any resources available?
- If you encounter any questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_salesforce/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran, or would like to request a future dbt package to be developed, then feel free to fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to just say hi? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or send us an email at solutions@fivetran.com.
