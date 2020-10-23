# Salesforce 

This package models Salesforce data from [Fivetran's connector](https://fivetran.com/docs/applications/salesforce). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1fB6aCiX_C1lieJf55TbS2v1yv9sp-AHNNAh2x7jnJ48/edit#slide=id.g3cb9b617d1_0_237).

The main focus of this package is enable users to better understand the performance of your opportunities. You can easily understand what is going on in your sales funnel and dig into how the members of your sales team are performing. 

## Models

The primary outputs of this package are described below. Staging and intermediate models are used to create these output models.

**model**|**description**
-----|-----
salesforce\_manager\_performance|Each record represents a manager, enriched with data about their team's pipeline, bookings, loses, and win percentages.
salesforce\_owner\_performance|Each record represents an individual member of the sales team, enriched with data about their pipeline, bookings, loses, and win percentages.
salesforce\_sales\_snapshot|A single row snapshot that provides various metrics about your sales funnel.
salesforce\_opportunity\_enhanced|Each record represents an opportunity, enriched with related data about the account and opportunity owner.


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
By default, this package looks for your Salesforce data in the `salesforce` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your Salesforce data is, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
    salesforce_schema: your_database_name
    salesforce_database: your_schema_name
```

For additional configurations for the source models, visit the [Salesforce source package](https://github.com/fivetran/dbt_salesforce_source).

## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn more about Fivetran [in the Fivetran docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
