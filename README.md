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


## Upcoming changes with dbt version 0.17.0

As a result of functionality being released with version 0.17.0 of dbt, there will be some upcoming changes to this package. The staging/adapter models will move into a seperate package, `salesforce_source`, that defines the staging models and adds a source for Salesforce data. The two packages will work together seamlessly. By default, this package will reference models in the source package, unless the config is overridden. 

There are a few benefits to this approach:
* If you want to manage your own transformations, you can still benefit from the source definition, documentation, and staging models of the source package.
* If you have multiple sets of Salesforce data in your warehouse, a package defining sources doesn't make sense. You will have to define your own sources and union that data together. At that point, you will still be able to make use of this package to transform their data.

When this change occurs, we will release a new version of this package.

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration

The following [variables](https://docs.getdbt.com/docs/using-variables) are needed to configure this package:

**variable**|**information**|**required**
-----|-----|-----
account|Table, model, or source containing account details|Yes
opportunity|Table, model, or source containing opportunity details|Yes
user|Table, model, or source containing user details|Yes
user\_role|Table, model, or source containing user role details|Yes


An example `dbt_project.yml` configuration:

```yml
# dbt_project.yml

...

models:
    salesforce:
        vars:
            account: "{{ source('salesforce', 'account') }}"   # or "{{ ref('salesforce_account_unioned'}) }}"
            opportunity: "{{ source('salesforce', 'opportunity') }}" 
            user: "{{ source('salesforce', 'user') }}"
            user_role: "{{ source('salesforce', 'user_role') }}"
```

## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Resources:
- Learn more about Fivetran [here](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
