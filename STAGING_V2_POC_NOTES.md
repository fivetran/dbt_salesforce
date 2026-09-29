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

## New macros (`macros/staging/`)

- **`normalize_column_payload(full_payload, schema_name, table_name)`** — drills into
  `payload[schema][table]` and lowercases keys for case-insensitive lookup. Returns `{}` (and
  therefore null-fills everything) if the schema or table isn't in the payload.
- **`apply_column_payload(staging_columns, column_payload)`** — the introspection-free
  replacement for `fivetran_utils.fill_staging_columns` (fed previously by
  `adapter.get_columns_in_relation`). Mirrors its exact branching and `alias` support: present
  columns pass through raw/uncast under their current name; absent columns get
  `cast(null as datatype)`.
- **`get_source_identifier(table_name, default=table_name)`** — resolves a table's physical
  identifier from the payload's `__identifier__`, falling back to `default` (the standard
  table name, or a caller-supplied literal for reserved-word cases). Used directly in
  `src_salesforce.yml`'s `identifier:` config (see below), not from a model.
- **`select_payload_fields(table_name, staging_columns)`** — the single call each model's
  `fields` CTE makes. Calls `source('salesforce', table_name)` and `normalize_column_payload`
  for this table's payload, then emits the complete `select ... from ...` body using
  `apply_column_payload` for the column list.

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
        cast(account_number as {{ dbt.type_string() }}) as account_number,
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,
        cast(description as {{ dbt.type_string() }}) as account_description,
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

`final` is hand-written SQL, not a macro call per column, but **every column is explicitly
cast** — not just the ones with a real type override. See "A real bug this caught" below for
why that's load-bearing, not just defensive style. `get_*_columns()` macros are unchanged from
`main` except for the removed `add_renamed_columns()` call — they're still
the single source of truth for datatypes used to null-fill absent columns.

`opportunity` keeps its extra `calculated` CTE (date-diff logic) unchanged, sourced from
`final` as before.

## A real bug this caught: `final` must cast every column, not just overridden ones

An earlier version of this POC only cast a column in `final` when the original code had an
explicit `datatype=` override (e.g. money fields cast to numeric), leaving everything else as
a bare, uncast reference — reasoning it looked like `stg_google_ads__campaign_stats`'s `final`.
That was wrong, and it broke on BigQuery, not DuckDB: `salesforce__campaign_performance`
failed with `No matching signature for operator = for argument types: STRING, INT64` joining
`stg_salesforce__campaign.campaign_id` (aliased from `id`, always a string) against
`stg_salesforce__opportunity.campaign_id`.

The old `coalesce_rename` macro this POC replaces **always** cast every column to its declared
`get_*_columns()` datatype, override or not — that was never just style. `fields`
(`apply_column_payload`, like `fill_staging_columns` before it) never casts a *present* column,
only a null-filled *absent* one, so a present column's actual type is whatever the warehouse
infers for the raw source column. BigQuery in particular will happily infer `INT64` for an
all-null/all-blank column with no explicit schema (exactly what `sf_opportunity_data.csv`'s
`campaign_id` column is in this seed) — silently swapped out from under a supposedly-`string`
column the moment nothing casts it. The old code's unconditional per-column cast was a real
safety net against this, not just defensive verbosity, and dropping it for "only cast where
overridden" broke real data on real warehouse type-inference behavior that DuckDB's own
(more permissive) inference didn't happen to reproduce.

Fixed by making every column in every `final` an explicit `cast(col as {{ datatype }}) as
alias_or_col` line, still hand-written plain SQL (no macro/dict lookup — that part of the
"look like other packages" goal holds), just with no column skipped. Re-verified: all 24
models (staging + downstream) build clean against DuckDB, and specifically
`salesforce__campaign_performance` (the model that surfaced this) succeeds.

**This also means the DuckDB-only verification used throughout this POC has a real blind
spot**: DuckDB's type inference is more permissive than BigQuery's, so a bug like this one
compiles and runs fine there and only surfaces on a stricter warehouse. Nothing else here was
re-checked against BigQuery/Snowflake/Postgres before this was caught by chance during manual
testing — see Open questions.

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
`get_source_identifier('order', default='"ORDER"')` for the Snowflake branch instead of
`var('salesforce_order_identifier', '"ORDER"')`.

The 14 `salesforce_<table>_identifier` vars in `integration_tests/dbt_project.yml` are gone —
nothing reads them anymore. The payload's `__identifier__` for each table (e.g.
`sf_account_data`) is now the only place that mapping is configured.

## Proof it works (all verified against a local DuckDB target, no warehouse creds needed)

- Zero `adapter.get_columns_in_relation` / `information_schema` anywhere in compiled SQL
  across all 14 staging models.
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
