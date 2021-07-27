[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=0.20.x&color=orange)
# Salesforce ([docs](https://dbt-salesforce.netlify.app/)) 

This package models Salesforce data from [Fivetran's connector](https://fivetran.com/docs/applications/salesforce). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1fB6aCiX_C1lieJf55TbS2v1yv9sp-AHNNAh2x7jnJ48/edit#slide=id.g3cb9b617d1_0_237).

The main focus of this package is enable users to better understand the performance of your opportunities. You can easily understand what is going on in your sales funnel and dig into how the members of your sales team are performing. 

## Models

The primary outputs of this package are described below. Staging and intermediate models are used to create these output models.

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
    version: [">=0.4.0", "<0.5.0"]
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
  salesforce:
    opportunity_enhanced_pass_through_columns: [account_custom_field_1, account_custom_field_2, opportunity_manager.user_custom_column]
  salesforce_source:
    account_pass_through_columns: [account_custom_field_1, account_custom_field_2]
    user_pass_through_columns: [user_custom_column]
```

For additional configurations for the source models, visit the [Salesforce source package](https://github.com/fivetran/dbt_salesforce_source).


## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.


## Database support
This package has been tested on BigQuery, Snowflake and Redshift.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate dbt transformations with Fivetran [here](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
