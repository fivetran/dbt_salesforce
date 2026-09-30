# Staging v2 POC: payload-driven columns, zero introspection

Branch: `feature/staging-v2-payload-poc`. This is a proof of concept, not a shippable
change — see Open questions at the bottom before building on it further.

## Why

Every one of the 14 `stg_salesforce__*` models ran a live `adapter.get_columns_in_relation()`
query at compile time to find out which columns actually exist in a customer's table. On top
of that, Salesforce carried extra jinja machinery found in no other Fivetran package —
`add_renamed_columns` guessed a camelCase spelling for every column, and `coalesce_rename`
coalesced whichever spelling actually existed. That machinery dates to
[PR #55](https://github.com/fivetran/dbt_salesforce/pull/55) (July 2024), when the connector
started normalizing raw Salesforce API field names (camelCase) to snake_case and the package
had to support both old and newly-synced customers without a hard break.

The introspective query is also a problem for dbt state/defer-based CI: it requires a live
warehouse round trip at compile time on every run.

The new approach: the quickstart runtime supplies an **exhaustive** payload var — for every
column a connector currently produces, its current name in the table (same as canonical if
not renamed, different if renamed). Presence, absence, and exact spelling are all known
upfront, so no SQL introspection is needed, and there's no more guessing.

## Payload format

One var for the whole package, `salesforce__column_payload`, keyed by schema, then by the
package's **standard** table name (the literal already passed to `source()`, e.g. `account` —
not the customer's physical table name):

```yaml
vars:
  salesforce:
    salesforce__column_payload:
      <schema>:
        account:
          __identifier__: sf_account_data   # the customer's actual physical table name
          account_number: AccountNumber     # renamed
          website: <absent — column doesn't exist for this customer>
          # ...every other column get_account_columns() declares
        campaign:
          __identifier__: sf_campaign_data
          ...
```

- Key present, value differs from key → renamed; select the value's spelling, alias back to
  the key.
- Key present, value equals key → not renamed.
- Key absent → doesn't exist for this customer; null-fill using the datatype from
  `get_*_columns()`.
- `__identifier__` is a sibling key in the same table dict, not a column — it's what
  `src_salesforce.yml`'s `identifier:` config reads to know which physical table to read from
  (see below), falling back to the standard table name if a table has no entry.
- No fallback to introspection: an unset/empty payload treats every column as absent.

Schema-then-table nesting (rather than one flat var per table) is the shape a future
multi-org/union implementation can extend by indexing on `source_relation` without another
payload format change.

## New macros

- **`select_payload_fields(source_name, table_name, staging_columns, payload_key=none)`**
  (`macros/staging/`) — the single call each model's `fields` CTE makes. Resolves
  `source(source_name, table_name)`, drills `salesforce__column_payload` down to
  `payload[schema][payload_key or table_name]`, and emits the complete `select ... from ...`
  body: present columns pass through raw/uncast under their current name (mirroring
  `fivetran_utils.fill_staging_columns`'s own branching and `alias` support), absent columns
  get `cast(null as datatype)`. Originally three macros (`normalize_column_payload` +
  `apply_column_payload` + `select_payload_fields`) — folded into one, since the other two
  were never called from anywhere else. `source_name` and the optional `payload_key` exist to
  let the same macro serve the `salesforce_history` source too (see below), not just
  `salesforce`.
- **`get_source_identifier(schema_name, payload_key, default=payload_key)`** (`macros/staging/`)
  — resolves a table's physical identifier from the same payload's `__identifier__`, falling
  back to `default` (the standard table name, or a caller-supplied literal for reserved-word
  cases). Used directly in a source yml's `identifier:` config (`schema_name` passed in
  explicitly, since this runs before `source()` itself can resolve it), never from a model.
- **`get_history_columns(base_columns, id_alias)`** (`macros/`, alongside the existing
  `history_spine_start_date`) — takes a core table's own `get_*_columns()` list and adds
  `_fivetran_start`/`_fivetran_end`, aliasing `id` to the history model's day-grain id column
  (e.g. `account_id`). Lets the 4 history models reuse the core `get_*_columns()` macros
  directly instead of near-duplicate `get_*_history_columns()` ones.

## Model shape

Restored to look like every other Fivetran package's staging layer — `fields` then `final`,
not the old salesforce-specific per-column macro/dict pattern. `get_account_columns()` is
called inline in the macro call, since nothing else in the model needs the column list:

```sql
with fields as (

    {{ salesforce.select_payload_fields('account', get_account_columns()) }}

),

final as (

    select
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        account_number,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        description as account_description,
        cast(id as {{ dbt.type_string() }}) as account_id,
        ...
        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
```

`final` is hand-written SQL, not a macro call per column, and only casts a column when it has
to: a genuine `datatype=` override from the original code (e.g. money fields cast to numeric,
`annual_revenue` above), or the column is used downstream in a join or a `coalesce()` against
another table (`account_id` above — see "A real bug this caught" for why that specific case is
load-bearing). Everything else is a bare reference or `col as alias`. `get_*_columns()` macros
are unchanged from `main` except for the removed `add_renamed_columns()` call and switching
every literal `"boolean"` datatype to `dbt.type_boolean()` for consistency — they're still the
single source of truth for datatypes used to null-fill absent columns.

`opportunity` keeps its extra `calculated` CTE (date-diff logic) unchanged, sourced from
`final` as before.

## A real bug this caught: `final` must cast join/coalesce columns, not just overridden ones

An earlier version of this POC only cast a column in `final` when the original code had an
explicit `datatype=` override, leaving everything else as a bare, uncast reference — reasoning
it looked like `stg_google_ads__campaign_stats`'s `final`. That was wrong, and it broke on
BigQuery, not DuckDB: `salesforce__campaign_performance` failed with `No matching signature for
operator = for argument types: STRING, INT64` joining `stg_salesforce__campaign.campaign_id`
(aliased from `id`, always a string) against `stg_salesforce__opportunity.campaign_id`.

The old `coalesce_rename` macro this POC replaces **always** cast every column to its declared
`get_*_columns()` datatype, override or not. `fields` (`apply_column_payload`, like
`fill_staging_columns` before it) never casts a *present* column, only a null-filled *absent*
one, so a present column's actual type is whatever the warehouse infers for the raw source
column. BigQuery in particular will happily infer `INT64` for an all-null/all-blank column with
no explicit schema (exactly what `sf_opportunity_data.csv`'s `campaign_id` column is in this
seed) — silently swapped out from under a supposedly-`string` column the moment nothing casts
it. The old code's unconditional per-column cast was a real safety net against this, and
dropping it for "only cast where overridden" broke real data on real warehouse type-inference
behavior DuckDB's own (more permissive) inference didn't happen to reproduce.

First fix cast *every* column unconditionally, matching the old behavior exactly. Correct but
more than necessary: the actual risk is narrower than "any column, any time" — it's specifically
columns whose value gets compared to another table's value (a join key) or combined with one
(inside a `coalesce()`), since that's the only place a silently-wrong inferred type causes a
real failure. Audited every downstream model (`models/salesforce/*.sql`,
`models/salesforce/intermediate/*.sql`) for `join ... on` and `coalesce(...)` referencing a raw
staging column, and now only those columns (plus the pre-existing `datatype=` overrides) stay
cast:

| Table | Cast for join/coalesce use | Reason |
| --- | --- | --- |
| account | `id` → `account_id` | joined in `contact_enhanced`, `opportunity_enhanced` |
| campaign | `id` → `campaign_id`, `campaign_member_record_type_id` | joined in `campaign_performance` |
| campaign_member | `campaign_id` | joined in `campaign_performance` |
| contact | `account_id`, `owner_id` | joined in `contact_enhanced` |
| event | `activity_date` | joined/`date_trunc`'d in `daily_activity` |
| lead | `created_date`, `converted_date` | joined/`date_trunc`'d in `daily_activity` |
| opportunity | `campaign_id`, `account_id`, `owner_id`, `record_type_id`, `created_date`, `close_date` | joined in `campaign_performance`, `opportunity_enhanced`, `daily_activity` |
| opportunity_line_item | `product_2_id` | joined in `opportunity_line_item_enhanced` |
| product_2 | `id` → `product_2_id` | joined in `opportunity_line_item_enhanced` |
| record_type | `id` → `record_type_id` | joined in `campaign_performance`, `opportunity_enhanced` |
| task | `activity_date` | joined/`date_trunc`'d in `daily_activity` |
| user | `id` → `user_id`, `manager_id`, `user_role_id`, `name` → `user_name` | joined throughout; `user_name` via `coalesce()` in `manager_performance` |
| user_role | `id` → `user_role_id` | joined in `manager_performance`, `opportunity_enhanced` |
| order | *(none)* | no downstream join/coalesce found |

`order` and most of the tables above went from every-column-cast back down to 1-7 cast lines
(matching only the table above plus pre-existing overrides), out of 6-43 total columns per
table. Re-verified: all 24 models build clean against DuckDB, and specifically
`salesforce__campaign_performance` still succeeds with the narrower cast set.

**This also means the DuckDB-only verification used throughout this POC has a real blind
spot**: DuckDB's type inference is more permissive than BigQuery's, so a bug like this one
compiles and runs fine there and only surfaces on a stricter warehouse. See Open questions.

This targeted-casting list was derived once, by hand, reading every downstream model's
joins/coalesces — it isn't enforced, so a new downstream join added later needs its join
column added here too, the same way the old `coalesce_rename` pattern already required
per-column setup for every new field. Treated as ordinary package maintenance (keep the cast
list in sync when adding a join), not a gap to close.

## What got deleted

- `macros/staging/add_renamed_columns.sql`, `coalesce_rename.sql`, `column_list_to_dict.sql` —
  the camelCase-guessing/coalescing machinery this POC replaces. Nothing calls them anymore.
- The 14 per-table `salesforce_<table>_identifier` vars in `integration_tests/dbt_project.yml`
  — see below, they're superseded by the payload's `__identifier__`.

An earlier pass through this POC also deleted the 14 `identifier:` overrides and the freshness
config in `src_salesforce.yml` outright, reasoning the FROM relation didn't need them since it
was built from the payload directly via `api.Relation.create()`. That broke the only tie
dbt's own tooling (docs, lineage, `dbt source freshness`) has to the real physical table, so
both came back — but pointed at the payload instead of the old per-table vars, closing that
gap for good instead of just patching around it.

## The identifier now comes from the payload at the `src_salesforce.yml` level

Each table's `identifier:` config went from:

```yaml
identifier: "{{ var('salesforce_account_identifier', 'account')}}"
```

to:

```yaml
identifier: "{{ salesforce.get_source_identifier('account') }}"
```

`get_source_identifier` reads the same `salesforce__column_payload` var everything else uses,
falling back to the literal standard name (`account`) if the payload has no entry — the same
default dbt itself would use with no `identifier:` at all. Since this is evaluated wherever
`source('salesforce', 'account')` is, `source(...)` now resolves to the payload's
`__identifier__` *directly* — no separate override needed in `select_payload_fields` anymore
(the earlier `api.Relation.create()` step is gone). This closes the gap flagged after the
previous pass: there's now exactly one source of truth for the identifier, and dbt's own
tooling (docs, lineage, `dbt source freshness`) sees the same one this package actually
queries, instead of the two independently-configured values silently drifting apart.

The order table keeps its Snowflake-reserved-word handling, just calling
`get_source_identifier(schema, 'order', default='"ORDER"')` for the Snowflake branch instead of
`var('salesforce_order_identifier', '"ORDER"')`.

The 14 `salesforce_<table>_identifier` vars in `integration_tests/dbt_project.yml` are gone —
nothing reads them anymore. The payload's `__identifier__` for each table (e.g.
`sf_account_data`) is now the only place that mapping is configured.

## History models now use the same payload-driven pattern

The 4 `salesforce__*_daily_history` models (`models/salesforce_history/`) had their own,
separate introspection mechanism: `dbt_utils.star(from=source('salesforce_history', table),
except=["id", "_fivetran_start", "_fivetran_end"])`, which under the hood is the same
`adapter.get_columns_in_relation` call this whole POC removes everywhere else — it was just
finding it through a different macro.

Replaced `dbt_utils.star(...)` with a `fields` CTE (`select_payload_fields('salesforce_history',
'account', salesforce.get_history_columns(get_account_columns(), 'account_id'),
payload_key='account_history')`), reusing the core table's own `get_*_columns()` macro instead
of writing 4 new near-duplicate ones (`get_history_columns` just adds
`_fivetran_start`/`_fivetran_end` and re-aliases `id`). The `_fivetran_date`/
`history_unique_key` computed columns and the rest of the spine/dedup logic are unchanged,
just now selecting from `fields` instead of `source(...)` directly.

`payload_key='account_history'` (not `'account'`) matters here: this fixture's
`salesforce_history_schema` is set to the same value as `salesforce_schema`
(`zz_dbt_catherine`), so the core `account` table and the history `account` table would
otherwise collide on the same `payload[schema]['account']` entry. `select_payload_fields` and
`get_source_identifier` both take an explicit `payload_key` (defaulting to `table_name`) for
exactly this — the core 14 calls didn't need to change.

**Behavior change worth flagging**: `dbt_utils.star()` exposed *every* column the introspected
table actually had, including undeclared/custom ones no `get_*_columns()` macro or
pass-through-columns var ever mentioned. Reusing `get_*_columns()` means a history model now
only outputs what the core staging model would also output (declared columns +
pass-through-columns var) — any raw column that only ever showed up via blanket introspection
disappears. Auditing all 4 history seeds against their actual physical columns (not just the
source yml's documented list, which turned out to be incomplete in 2 of 4 cases — see
"Proof it works" below) surfaced 4 columns declared in `get_*_columns()` that don't exist in
this fixture's history seeds; removed from the payload so they null-fill instead of erroring.

## Proof it works (all verified against a local DuckDB target, no warehouse creds needed)

- Zero `adapter.get_columns_in_relation` / `information_schema` / `dbt_utils.star` anywhere in
  compiled SQL across all 14 staging models and all 4 history models.
- **All 28 models build clean**: 14 staging + 10 downstream (intermediate/enhanced/performance)
  + 4 history, `--full-refresh`, with only the same pre-existing docs-mismatch warnings seen
  throughout this POC — none new.
- **History payload audit found real gaps twice**: querying each history seed's actual
  physical columns (via `describe`, not the source yml's documented list) turned up 3 columns
  on `account_history` (`billing_state_code`, `shipping_country_code`, `shipping_state_code`)
  and 1 on `contact_history` (`department`, then later `mailing_state_code`) that `main`'s
  `src_salesforce_history.yml` never documented and that don't exist in this fixture's seeds,
  even though the corresponding core `get_*_columns()` macro declares them. Removed from the
  payload so they null-fill instead of throwing "column not found" / a confusing DuckDB binder
  error. A reminder that this payload has to reflect the real table, not the declared list.
- **Rename, no introspection**: `sf_opportunity_data.csv`'s `description` column renamed to
  `Description__c`, mapped via the payload — resolves correctly
  (`fields`: `Description__c as description`; `final`: `description as opportunity_description`).
- **Rename, camelCase (the actual historical case)**: `sf_account_data.csv`'s `account_number`
  renamed to `AccountNumber` — same result.
- **Missing column**: `website` dropped entirely from `sf_account_data.csv` and its payload
  entry — null-fills correctly (`cast(null as TEXT) as website`).
- **Isolated macro unit test** (via `dbt run-operation`): confirmed null-fill and
  case-insensitive payload-key matching independent of any seed data.
- **Identifier resolution**: confirmed `source('salesforce','account')` itself (not a
  separately-built relation) resolves to `sf_account_data`, the payload's `__identifier__`.
  With the payload emptied out entirely, confirmed the fallback correctly resolves to the
  literal `account` (a real "table not found" error against this project's `sf_`-prefixed
  seeds, not a crash or a silent wrong-table query) — proving the fallback chain works even
  though it doesn't happen to match this particular project's seed naming.

## Open questions / follow-ups (not resolved by this POC)

- **How the real quickstart runtime supplies this var per customer** — this POC hand-authors
  it in `integration_tests/dbt_project.yml`; production wiring is undesigned.
- **`get_source_identifier` in `identifier:` only works on dbt 2.0 (the Fusion-era engine,
  tested here as `dbt-oss 2.0.5`), not real dbt-core.** Confirmed directly: real dbt-core
  1.11.12 fails `identifier: "{{ salesforce.get_source_identifier('account') }}"` with
  `Compilation Error: Could not render ...: 'salesforce' is undefined` — reproduced with the
  actual `dbt-core==1.11.12` package, not just inferred. dbt-core's YAML property-file Jinja
  rendering only exposes built-in globals (`var`, `env_var`, `target`, ...), never custom
  package macros, even self-namespaced ones; dbt 2.0 evidently renders source config with the
  full macro context available. **This POC's `identifier:` design is dbt-2.0-only by explicit
  choice** (see conversation) — it will not work as-is on any dbt-core 1.x project, which is
  what real customers run today. If this ships before dbt-core parity (or for a dbt-core
  target), `identifier:` needs to go back to a plain `var()`-based per-table default (as it was
  before this POC), with the payload's `__identifier__` handled as a runtime override inside
  `select_payload_fields` (via `api.Relation.create()`) instead of at the yml level.
- **The payload's top-level schema key is a manual sync point.** Hit this directly switching
  the integration_tests target from DuckDB to BigQuery: `salesforce_schema` was changed to
  `zz_dbt_catherine` without updating `salesforce__column_payload`'s outer key (still
  `salesforce_integrations_tests_4`), so every lookup missed and every identifier silently fell
  back to the literal table name — the exact same `Table ... was not found` failure as the
  dbt-core/dbt-2.0 issue above, but from stale config instead of a rendering limitation. Not a
  bug in the resolution logic, but a real footgun for a hand-maintained fixture; a real
  quickstart-supplied payload wouldn't have this problem since it would always be keyed to
  wherever it's actually deploying.
- **Multi-org/union** — the schema-keyed structure should extend to per-`source_relation`
  payloads, but no union model was built or tested here (this package doesn't currently union
  multiple Salesforce orgs in staging).
- **Upstreaming** — `apply_column_payload`/`normalize_column_payload` are Salesforce-local for
  now. If this pattern proves out, `fivetran_utils` is the natural home (same precedent as the
  existing `add_pass_through_columns` trio), so other packages could adopt it.
