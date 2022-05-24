<!---
Provide a short summary in the Title above. IMPORTANT: Prefix your commit title with the Jira ticket number the PR is associated with.
Examples of good PR titles:
* "GUM-25 Feature: add so-and-so models"
* "GUM-52 Fix: deduplicate such-and-such"
* "GUM-15 Update: dbt version 0.13.0"
-->

**What change(s) does this PR introduce?**
<!--- Describe what changes your PR introduces to the package and how to leverage this new feature. -->

**Does this PR introduce a breaking change?**
<!--- Does this PR introduce changes that will cause current package users' jobs to fail or require a `--full-refresh`? -->
<!--- To select a checkbox you simply need to add an "x" with no spaces between the brackets (eg. [x] Yes). -->
- [ ] Yes (please provide breaking change details below.)
- [ ] No  (please provide an explanation as to how the change is non-breaking below.)

## To-do before merge
Include any notes about things that need to happen before this PR is merged, e.g.:
- [ ] Refresh GDS Data Source
- [ ] Update dbt Cloud jobs
- [ ] Update package repo PR #__
- [ ] Ensure PR #__ is merged

## Screenshots:
<!---
Include a screenshot of the relevant section of the updated DAG. You can access
your version of the DAG by running `dbt docs generate && dbt docs serve`.
-->

## Checklist:
<!---
This checklist is mostly useful as a reminder of small things that can easily be
forgotten – it is meant as a helpful tool rather than hoops to jump through.
Put an `x` in all the items that apply, make notes next to any that haven't been
addressed, and remove any items that are not relevant to this PR.
-->
- [ ] My pull request represents one logical piece of work.
- [ ] My commits are related to the pull request and look clean.
- [ ] My SQL follows the [dbt Labs style guide](https://github.com/dbt-labs/corp/blob/master/dbt_style_guide.md).
- [ ] I have materialized my models appropriately.
- [ ] I have added appropriate tests and documentation to any new models.

**Help us visualize the world this PR creates**
<!--- For a complete list of markdown compatible emojis check our this git repo (https://gist.github.com/rxaviers/7360908)  -->
🌮
