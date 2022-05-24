[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Salesforce ([docs](https://dbt-salesforce.netlify.app/)) 

This package models Salesforce data from [Fivetran's connector](https://fivetran.com/docs/applications/salesforce). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1fB6aCiX_C1lieJf55TbS2v1yv9sp-AHNNAh2x7jnJ48/edit#slide=id.g3cb9b617d1_0_237).

The main focus of this package is enable users to better understand the performance of your opportunities. You can easily understand what is going on in your sales funnel and dig into how the members of your sales team are performing. 

## Models

The primary outputs of this package are described below. Staging and intermediate models are used to create these output models. This package contains transformation models, designed to work simultaneously with staging models in our [Salesforce source package](https://github.com/fivetran/dbt_salesforce_source).

**model**|**description**
-----|-----
salesforce\_\_manager\_performance|Each record represents a manager, enriched with data about their team's pipeline, bookings, losses, and win percentages.
salesforce\_\_owner\_performance|Each record represents an individual member of the sales team, enriched with data about their pipeline, bookings, losses, and win percentages.
salesforce\_\_sales\_snapshot|A single row snapshot that provides various metrics about your sales funnel.
salesforce\_\_opportunity\_enhanced|Each record represents an opportunity, enriched with related data about the account and opportunity owner.


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in your `packages.yml`

```yaml
packages:
  - package: fivetran/salesforce
    version: [">=0.5.0", "<0.6.0"]
```

## Configuration
By default, this package looks for your Salesforce data in the `salesforce` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your Salesforce data is, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
    salesforce_schema: your_schema_name
    salesforce_database: your_database_name
```

This package allows users to add additional columns to the opportunity enhanced table. Columns passed through must be present in the downstream source account table or user table. If you want to include a column from the user table, you must specify if you want it to be a field relate to the opportunity_manager or opportunity_owner.

```yml
# dbt_project.yml

...
vars:
  opportunity_enhanced_pass_through_columns: [account_custom_field_1, account_custom_field_2, opportunity_manager.user_custom_column]
  account_pass_through_columns: [account_custom_field_1, account_custom_field_2]
  user_pass_through_columns: [user_custom_column]
```

### Salesforce History Mode
If you have Salesforce [History Mode](https://fivetran.com/docs/getting-started/feature/history-mode) enabled for your connector, the source tables will include all historical records. This package is designed to deal with non-historical data. As such, if you have History Mode enabled you will want to set the desired `using_[table]_history_mode_active_records` variable(s) as `true` to filter for only active records. These variables are disabled by default; however, you may add the below variable configuration within your `dbt_project.yml` file to enable the feature.
```yml
# dbt_project.yml

...
vars:
  using_account_history_mode_active_records: true      # false by default. Only use if you have history mode enabled.
  using_opportunity_history_mode_active_records: true  # false by default. Only use if you have history mode enabled.
  using_user_role_history_mode_active_records: true    # false by default. Only use if you have history mode enabled.
  using_user_history_mode_active_records: true         # false by default. Only use if you have history mode enabled.
```

### Disabling Models
Your connector may not be syncing all tabes that this package references. This might be because you are excluding those tables. If you are not using those tables, you can disable the corresponding functionality in the package by specifying the variable in your dbt_project.yml. By default, all packages are assumed to be true. You only have to add variables for tables you want to disable, like so:

The `salesforce__user_role_enabled` variable below refers to the `user_role` table. 

```yml
# dbt_project.yml

...
config-version: 2

vars:
  salesforce__user_role_enabled: false # Disable if you do not have the user_role table

```
The corresponding metrics from the disabled tables will not populate in downstream models.

## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `main`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.


## Database support
This package has been tested on BigQuery, Snowflake, Redshift, Postgres, and Databricks.

### Databricks Dispatch Configuration
dbt `v0.20.0` introduced a new project-level dispatch configuration that enables an "override" setting for all dispatched macros. If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
# dbt_project.yml

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate your models with [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
