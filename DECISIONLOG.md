## Consolidating the account, contact, and opportunity history models
The `account`, `contact`, and `opportunity` daily history models originally carried over the two-model structure (a staging model plus a daily history model) inherited from the retired `dbt_salesforce_source` package. The `campaign` daily history model, added later, used a simpler single-model structure that reads directly from `source()`.

We consolidated `account`, `contact`, and `opportunity` to match the `campaign` structure, removing the intermediate staging models (`stg_salesforce__account_history`, `stg_salesforce__contact_history`, `stg_salesforce__opportunity_history`). This removes a layer of indirection with no remaining purpose now that vars only reference sources (see the `v2.0.0` breaking change), and keeps all four history models consistent with each other.

**This requires a `--full-refresh` of the four daily history models** (`salesforce__account_daily_history`, `salesforce__contact_daily_history`, `salesforce__opportunity_daily_history`, and `salesforce__campaign_daily_history`), since the underlying `unique_key` logic and incremental boundary changed (see below).

## Rebuilding the history models' incremental boundary
Previously, each daily history model determined its spine range independently of the filter applied to incoming source history records: the date spine was regenerated from the configured start date through the current date on every run, while the source history pull was filtered to only the records with a `_fivetran_start` newer than the latest one already in the target.

This meant a record that remained current but had not changed recently could fall outside the source filter on an incremental run, so it would never be joined to the newly generated spine dates. In practice, entities that stopped changing would silently stop receiving new daily rows.

We fixed this by computing a single shared boundary per run (`spine_start_date`, the latest `date_day` already materialized, or the configured start date on the first run) that drives both:
- Which spine dates get (re)generated: from `spine_start_date` through `current_date`, instead of the full configured history range.
- Which source history records are pulled: any record whose `_fivetran_end` is on or after `spine_start_date`, rather than only records with a recent `_fivetran_start`. This naturally re-includes currently open records regardless of how long ago they last changed, while still excluding records that closed before the new window.

This also means the model no longer rebuilds the full date spine on every incremental run, only the dates that could actually change.

**Known limitation:** This design does not automatically pick up a corrected or backfilled history record that lands with a `_fivetran_start`/`_fivetran_end` overlapping a date range that has already been materialized (i.e., before `spine_start_date`). If your Salesforce History Mode connection ever needs to correct already-synced history, run a `--full-refresh` on the affected daily history model(s) to pick up the correction.

**Assumption validated during testing:** The spine join (`_fivetran_start <= date_day AND _fivetran_end >= date_day`) relies on consecutive versions of the same record never overlapping at the day grain, i.e. that `_fivetran_end` is always the next version's `_fivetran_start` minus epsilon, per the column's documented definition. We validated this holds (no duplicate or missing daily rows across a same-day version change) as long as that epsilon gap is respected; a source record with `_fivetran_end` exactly equal to the next version's `_fivetran_start` would produce a duplicate `*_day_id` on the transition date.

## Renaming `description` and `name` on the history models
The `account`, `contact`, and `opportunity` daily history models select every field from their respective Salesforce History Mode source table, including the generic `description` and `name` columns. Every other model in this package disambiguates these same fields with an entity-specific alias (for example, `stg_salesforce__account` renames `description` to `account_description` and `name` to `account_name`), since generic names like these are easy to collide with when a model is joined downstream.

As part of the consolidation above, we aligned the history models with this convention by explicitly renaming `description`/`name` to `account_description`/`account_name`, `contact_description`/`contact_name`, and `opportunity_description`/`opportunity_name`, respectively. This is a breaking change for any downstream query currently referencing the unprefixed `description` or `name` columns on these three history models.

## Syncing all of your fields from the Salesforce History Mode connector
When creating these new History Mode models, our hypothesis was that the primary reason customers would leverage this data would be to view changes in historical records.

Our normal process is to allow customers to pick and choose the custom fields they bring into their end models. However, omitting any fields that are being synced will lead to new rows of historical records having duplicate data, thus missing out on the potentially. 

Our conclusion was that there is more value for a customer to leverage the history tables if they are syncing all fields they are using, and can thus view all the historical changes in the records they are using. 

There is the drawback of a significant amount of data processing and very large tables with a huge number of columnar values, but we felt this version made the most sense for customers who really want to unlock historical data on their Salesforce tables. 

We are open to feedback on how to improve these history models at all time, [so please contact us directly via our many channels](https://github.com/fivetran/dbt_salesforce_source#-how-is-this-package-maintained-and-can-i-contribute)!