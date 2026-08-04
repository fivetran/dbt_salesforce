## History models' incremental boundary
The `account`, `campaign`, `contact`, and `opportunity` daily history models compute a single shared boundary per run (`spine_start_date`) that drives both:
- Which spine dates get (re)generated: from `spine_start_date` through `current_date`, rather than the full configured history range.
- Which source history records are pulled: any record whose `_fivetran_end` is on or after `spine_start_date`. This is deliberately `_fivetran_end`, not `_fivetran_start` -- a record's `_fivetran_start` doesn't change just because it's still open, but whether it's relevant to a given spine date is entirely determined by whether its validity (`_fivetran_end`) still covers that date.

`spine_start_date` is computed via the `salesforce_lookback` macro (the same pattern used by several other Fivetran packages, e.g. `netsuite_lookback`, `jira_lookback`), which looks back `lookback_window` days (default 1) from the latest materialized `date_day` rather than starting exactly where the last run left off. This means a corrected or backfilled history record landing within that window is picked up automatically on the next incremental run.

**Known limitation:** A correction landing further back than the configured `lookback_window` still requires a `--full-refresh` on the affected daily history model(s) to be picked up.

**Assumption the spine join relies on:** The join (`_fivetran_start <= date_day AND _fivetran_end >= date_day`) assumes consecutive versions of the same record never overlap at the day grain, i.e. that `_fivetran_end` is always the next version's `_fivetran_start` minus epsilon, per the column's documented definition. A source record with `_fivetran_end` exactly equal to the next version's `_fivetran_start` would produce a duplicate `*_day_id` on the transition date.

## Syncing all of your fields from the Salesforce History Mode connector
When creating these new History Mode models, our hypothesis was that the primary reason customers would leverage this data would be to view changes in historical records.

Our normal process is to allow customers to pick and choose the custom fields they bring into their end models. However, omitting any fields that are being synced will lead to new rows of historical records having duplicate data, thus missing out on the potentially. 

Our conclusion was that there is more value for a customer to leverage the history tables if they are syncing all fields they are using, and can thus view all the historical changes in the records they are using. 

There is the drawback of a significant amount of data processing and very large tables with a huge number of columnar values, but we felt this version made the most sense for customers who really want to unlock historical data on their Salesforce tables. 

We are open to feedback on how to improve these history models at all time, [so please contact us directly via our many channels](https://github.com/fivetran/dbt_salesforce_source#-how-is-this-package-maintained-and-can-i-contribute)!