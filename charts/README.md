# Salesforce boards

These dbt Charts boards query `salesforce__opportunity_enhanced` from this package
through `ref()`. Install the package in a dbt project, build its models, and
generate a manifest with `dbt parse`. Run the boards from that project with a
configured warehouse source. Query SQL declares `dialect: duckdb` for warehouse
translation.

- `pipeline.yml`: current open opportunities, past expected close dates, pipeline
  by stage and close month, and the top 20 owners by pipeline amount.
- `win-loss.yml`: closed opportunity counts, win rate, won amount, monthly
  outcomes, and lead-source performance.

Amount totals assume comparable units in the package's `amount` column. These
boards apply no foreign-exchange conversion. The pipeline board shows the current
open snapshot; historical pipeline reconstruction needs the package's optional
history models. Date filters are unset initially, so all dates are included.
