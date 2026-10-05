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
- `__identifier__` is a sibling key in the same table dict, not a column — `select_payload_fields`
  reads it (via `get_source_identifier`) to know which physical table to actually read from
  (see below), falling back to the yml/var-configured identifier if a table has no entry.
- No fallback to introspection: an unset/empty payload treats every column as absent.

**The schema level is looked up leniently, not by exact match, whenever there's only one.**
`select_payload_fields` and `get_source_identifier` both check `salesforce__column_payload`'s
own length first: if it has exactly one schema entry, that entry is used directly, full stop
— `salesforce_schema`/`salesforce_history_schema` aren't even consulted. Exact matching against
those vars only happens once a *second* schema entry actually shows up in the payload. This
schema-then-table shape (rather than a flat `payload[table]`) is prepared for a future
multi-org/union package, where genuinely disambiguating between schemas matters — but exact
schema matching by itself was tried first here and caused two separate real failures:
switching `salesforce_schema` for BigQuery testing without also updating the payload's schema
key broke every identifier lookup, silently falling back to the literal table name (see the
BigQuery run in the conversation). The single-schema shortcut exists specifically so that a
package which — like Salesforce — never actually has more than one schema in play can't be
broken by that kind of drift, while still being schema-shaped for when a package that does
union genuinely needs it. Verified directly: compiling with `salesforce_schema` overridden to
an arbitrary, unrelated value still resolves the identifier correctly (single-schema payload,
shortcut kicks in); a payload with two schema entries correctly picks the queried one, or falls
back to the literal default for a schema that matches neither (exact matching kicks in once
there's real ambiguity to resolve).

## New macros

- **`select_payload_fields(source_name, table_name, staging_columns, payload_key=none)`**
  (`macros/staging/`) — the single call each model's `fields` CTE makes. Resolves
  `source(source_name, table_name)`, calls `get_source_identifier` to build an *overriding*
  relation via `api.Relation.create()` (see below for why this override lives here and not in
  the source yml), drills `salesforce__column_payload` down to `payload[schema][payload_key or
  table_name]` (using the single-schema shortcut described above), and emits the complete
  `select ... from ...` body: present columns pass through, quoted, under their current name
  (mirroring `fivetran_utils.fill_staging_columns`'s own branching and `alias` support), absent
  columns get `cast(null as datatype)`. Originally three macros (`normalize_column_payload` +
  `apply_column_payload` + `select_payload_fields`) — folded into one, since the other two were
  never called from anywhere else. `source_name` and the optional `payload_key` exist to let
  the same macro serve the `salesforce_history` source too (see below), not just `salesforce`.
- **`get_source_identifier(schema_name, payload_key, default=payload_key)`** (`macros/staging/`)
  — resolves a table's physical identifier from the same payload's `__identifier__`, falling
  back to `default`. Called from `select_payload_fields` (a model-context macro call), *not*
  from a source yml's `identifier:` config — see below for why that distinction matters. Same
  single-schema shortcut as `select_payload_fields`.
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

    {{ salesforce.select_payload_fields('salesforce', 'account', get_account_columns()) }}

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

That's it, in the end. Two earlier passes through this POC also deleted (then partially
restored, then fully restored) the 14 per-table `identifier:` overrides, the freshness config,
and the `salesforce_<table>_identifier` vars — see the next section for why they're back to
looking exactly like `main`, unchanged.

## The identifier override lives in `select_payload_fields`, not in `identifier:` — confirmed by real CI, not just reasoning

This went through three designs before landing. First: delete the yml `identifier:` overrides
entirely, since the FROM relation was built straight from the payload via
`api.Relation.create()` — broke dbt's only tie to the real physical table (docs, lineage,
`dbt source freshness`). Second: point `identifier:` itself at a new `get_source_identifier(...)`
macro, so `source(...)` resolved to the payload's `__identifier__` directly — this compiled
fine under `dbt-oss 2.0.5` (the engine used for most of this POC's local verification) and
seemed like a clean unification, until **this package's own Buildkite CI failed identically on
all three of its targets** (postgres, snowflake, duckdb) at `dbt seed`, before any actual data
testing even started:

```
Compilation Error
Could not render {{ salesforce.get_source_identifier(var('salesforce_schema', 'salesforce'), 'account') }}: 'salesforce' is undefined
```

Real dbt-core's YAML property-file Jinja rendering only exposes built-in globals (`var`,
`env_var`, `target`, ...) — never custom package macros, even self-namespaced ones. `dbt-oss
2.0.5` evidently renders source config with the full macro context available, which is why
local testing never caught this; CI, running real `dbt-core 1.11.15`, did. Confirmed
independently and interactively too, against a real `dbt-core==1.11.12` install, before this
was even pushed.

**Final design**: `src_salesforce.yml`'s 14 `identifier:` configs (and `src_salesforce_history.yml`'s
4) are back to exactly what they were on `main` — plain `var('salesforce_<table>_identifier',
'<table>')`, including the `salesforce_<table>_identifier` vars in
`integration_tests/dbt_project.yml` and order's Snowflake-reserved-word branch. `source(...)`
itself is untouched by any of this POC's payload machinery. `select_payload_fields`
(a normal macro, called from a model, where custom macros always work) calls
`get_source_identifier` internally and builds an *overriding* relation with
`api.Relation.create()`, falling back to `source(...)`'s own plain-var identifier (not a bare
literal) when the payload has no entry. `get_source_identifier`'s own implementation didn't
need to change at all — only who calls it, and from where.

Re-verified end to end against **real dbt-core** (not `dbt-oss`) this time: `dbt parse` against
a real `dbt-core==1.11.12` install succeeds (the exact command that used to fail), and all 28
models build clean against a real Postgres instance (the same kind of warehouse Buildkite CI
itself uses) with real `dbt-core 1.11.12`.

### A second, distinct bug this same real-Postgres run caught

`stg_salesforce__account`/`stg_salesforce__opportunity` failed against real Postgres with
`column "accountnumber" does not exist` / `column "description__c" does not exist` — Postgres
folds an *unquoted* identifier to lowercase, so the compiled `AccountNumber as account_number`
(bare, unquoted) resolved to a column literally named `accountnumber`, which doesn't exist —
the actual column, created by `dbt seed`, is case-preserved as `AccountNumber`. `select_payload_fields`
now always quotes a resolved current-name reference (`quote_column({"name": current_name,
"quote": true})`), reusing the same per-warehouse quoting `quote_column` already had (including
Snowflake's uppercase-folding special case). Quoting a plain lowercase/underscore name this way
is a no-op on every warehouse, so the common (unrenamed) case is unaffected. Re-verified: both
models build clean against real Postgres afterward, and querying the account demo row directly
confirms `account_number = 'ACC-100234'` (rename resolved, correctly quoted) and `website =
NULL` (missing column) — on a real warehouse, under real dbt-core, not just DuckDB under
`dbt-oss`.

**This is the second time in this POC that DuckDB-only (or `dbt-oss`-only) verification missed
something a real target caught** — first the BigQuery type-inference/casting bug, now this
identifier-in-yml limitation and the Postgres case-folding bug. Neither DuckDB nor `dbt-oss`
are a substitute for testing against what CI (and customers) actually run.

### Reversed again: this package targets v2 (`dbt-oss`/Fusion) only, not v1 compatibility

The "move the override into `select_payload_fields`" fix above made both `[dbt v1]` (real
dbt-core) and `[dbt v2]` (`dbt-oss`/Fusion) CI lanes pass. That was the right call *while it
looked like a real-dbt-core compatibility bug was the only open question*. It wasn't the actual
goal: this POC is deliberately v2-only, and the earlier confusion about "v2 failures" (build
#272) was a separate, unrelated bug — the schema-key drift bug, fixed by the single-schema
shortcut — not evidence that the yml-based identifier design itself was broken under v2. Once
that was untangled, there was no remaining reason to carry the `api.Relation.create()`
override-in-macro design just to keep real dbt-core working.

So this reverses back to the second design above: `identifier:` in both source ymls calls
`salesforce.get_source_identifier(...)` directly again, `select_payload_fields` reads straight
from `source(source_name, table_name)` with no override relation, and the 18 now-redundant
`salesforce_<table>[_history]_identifier` vars are gone from `integration_tests/dbt_project.yml`
again (the payload's own `__identifier__` field is the only source of truth). The Postgres
case-folding quoting fix is unrelated to identifier placement and was kept as-is.

**Consequence, accepted deliberately**: real dbt-core (`[dbt v1]` in this package's CI) will
fail again at `dbt seed`/parse with `Could not render {{ salesforce.get_source_identifier(...)
}}: 'salesforce' is undefined` — reproduced directly against a real `dbt-core==1.11.12` install
to confirm it's the same failure mode CI hit before, not a new one. `[dbt v2]` (`dbt-oss 2.0.5`)
is unaffected: full `dbt seed` + `dbt run` (all 28 models, history included) succeeds with zero
errors, `dbt parse` succeeds, the identifier resolves to the payload's `__identifier__` (e.g.
`from "postgres"."zz_dbt_catherine"."sf_opportunity_data"` in compiled SQL, confirmed against a
real DuckDB build), and both the account rename/null-fill demo and the opportunity
`description` → `Description__c` rename demo still resolve correctly.

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

`payload_key='account_history'` (not `'account'`) matters here: both the core `salesforce`
source and the `salesforce_history` source live in the *same* schema in this fixture
(`salesforce_history_schema` is set to the same value as `salesforce_schema`), so the core
`account` table and the history `account` table would otherwise collide on the same
`payload[schema]['account']` entry. `select_payload_fields` and `get_source_identifier` both
take an explicit `payload_key` (defaulting to `table_name`) for exactly this — the core 14
calls didn't need to change.

**Behavior change worth flagging**: `dbt_utils.star()` exposed *every* column the introspected
table actually had, including undeclared/custom ones no `get_*_columns()` macro or
pass-through-columns var ever mentioned. Reusing `get_*_columns()` means a history model now
only outputs what the core staging model would also output (declared columns +
pass-through-columns var) — any raw column that only ever showed up via blanket introspection
disappears. Auditing all 4 history seeds against their actual physical columns (not just the
source yml's documented list, which turned out to be incomplete in 2 of 4 cases — see
"Proof it works" below) surfaced 4 columns declared in `get_*_columns()` that don't exist in
this fixture's history seeds; removed from the payload so they null-fill instead of erroring.

### A third real bug, this time caught by this package's own Buildkite CI

Real CI (`bigquery v1`, i.e. real dbt-core against BigQuery) failed after the identifier fix
above, in a spot local testing (DuckDB and real Postgres both) never exercised:

```
No matching signature for operator <= for argument types: DATETIME, TIMESTAMP
Signature: T1 <= T1
```

in `daily_history`'s `join spine on get_latest_daily_value._fivetran_start <= cast(spine.date_day
as {{ dbt.type_timestamp() }})`. The original pre-POC code explicitly cast `_fivetran_start`/
`_fivetran_end` to `dbt.type_timestamp()` the moment they were read out of `dbt_utils.star()`'s
exclusion, guaranteeing a consistent type before any later comparison. This POC's `fields` CTE
(`select_payload_fields`) never casts a *present* column by design (see the account/opportunity
cast audit above) — `_fivetran_start`/`_fivetran_end` pass straight through from the raw source
column, whatever BigQuery happens to have stored them as (`DATETIME`, not `TIMESTAMP`, in this
seed), and nothing re-cast them before the join that needed them to match.

Missed in the earlier join/coalesce cast audit because that audit was done against the 14 core
staging models before the history models existed in their payload-driven form — exactly the
"a new join needs its columns added to the cast list" maintenance case flagged as accepted
above, just one step removed (a *new model*, not a new join in an existing one). Fixed the same
way as the `campaign_id` bug: cast both join operands explicitly at the comparison
(`cast(get_latest_daily_value._fivetran_start as {{ dbt.type_timestamp() }}) <= cast(spine.date_day
as {{ dbt.type_timestamp() }})`) in all 4 history models, rather than restructuring their
`select *` (portably excluding two columns from a wildcard isn't supported the same way across
all 6 warehouses this package targets). Re-verified against real Postgres and DuckDB (no
BigQuery credentials available for interactive testing) — real CI is the actual confirmation
for the BigQuery-specific case this fix targets.

**This package's own CI (`fivetran/dbt-salesforce` on Buildkite) runs each of 6 warehouses
twice — once under real dbt-core (`v1`) and once under the newer engine (`v2`, i.e. `dbt-oss`)
— so it's a strictly stronger check than anything done locally in this POC.** Every fix in this
document that came from "real CI failed" was caught by the `v1` lane specifically; the `v2`
lane consistently passed throughout (including on the commit that first introduced
`get_source_identifier` in `identifier:`), which is exactly why local testing under `dbt-oss`
never caught what `v1` did. An earlier commit in this same PR (build #272) also had every `v2`
job failing, from the schema-key-drift bug fixed a few commits before this — so "run under v2"
is not by itself a substitute for "run under v1," and both lanes matter.

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
  renamed to `AccountNumber` — same result. The seed's first row (`account_name = 'Acme Test
  Corp'`) carries a real, visible value (`ACC-100234`) in the renamed field rather than blank,
  and a few realistic peer values (`industry`, `type`, `annual_revenue`, `description`) so the
  rename is actually visible in query output, not just confirmable by reading compiled SQL.
- **Missing column**: `website` dropped entirely from `sf_account_data.csv` and its payload
  entry — null-fills correctly (`cast(null as TEXT) as website`). Against that same fully-
  populated demo row, `website` comes back `NULL` while every other field has a real value —
  visibly, not just theoretically, the missing-column column.
- **Isolated macro unit test** (via `dbt run-operation`): confirmed null-fill and
  case-insensitive payload-key matching independent of any seed data.
- **Identifier resolution**: confirmed the *overriding* relation `select_payload_fields` builds
  via `api.Relation.create()` resolves to `sf_account_data`, the payload's `__identifier__` —
  `source('salesforce','account')` itself keeps its own plain-var identifier, unaffected. With
  the payload emptied out entirely, confirmed the fallback correctly resolves to that
  plain-var identifier rather than a bare literal or a crash.
- **Schema shortcut/exact-match, both directions**: with `salesforce_schema` overridden to an
  arbitrary, unrelated value against this fixture's single-schema payload, the identifier still
  resolved correctly (shortcut). With a synthetic two-schema payload, querying the schema that's
  actually present returned that schema's identifier, and querying a schema present in neither
  entry fell back to the literal default rather than picking either schema's data (exact match).
- **Real dbt-core, real Postgres, real CI** (see the dedicated section above for the full
  story): `dbt parse` against a real `dbt-core==1.11.12` install succeeds — the exact command
  that used to fail. All 28 models build clean against a real Postgres instance under real
  dbt-core, and querying the account demo row directly on that real warehouse confirms
  `account_number = 'ACC-100234'` (rename, correctly quoted) and `website = NULL` (missing
  column) — matching what DuckDB/`dbt-oss` had already shown, but now on infrastructure that
  actually reflects what customers and CI run.

## Open questions / follow-ups (not resolved by this POC)

- **How the real quickstart runtime supplies this var per customer** — this POC hand-authors
  it in `integration_tests/dbt_project.yml`; production wiring is undesigned.
- **Resolved, not open**: an earlier design called `get_source_identifier` directly from
  `identifier:` in the source yml, on the assumption it would work like `dbt-oss 2.0.5` (used
  for most of this POC's local verification) rendered it. This package's real Buildkite CI,
  running real `dbt-core 1.11.15`, failed identically on all three targets at `dbt seed` —
  real dbt-core's YAML property-file Jinja never exposes custom macros, only built-ins. Fixed
  by moving the identifier override into `select_payload_fields` (a model-context macro call,
  where custom macros always work) and restoring `identifier:` to plain `var()` calls
  identical to `main`. Re-verified against a real `dbt-core==1.11.12` install and a real
  Postgres instance. Left here as a record of what broke and why, not as something still open.
- **Resolved, not open**: the payload's top-level schema key originally had to be kept in sync
  by hand with `salesforce_schema`/`salesforce_history_schema` — hit this directly switching
  the integration_tests target from DuckDB to BigQuery, where `salesforce_schema` changed but
  the payload's outer key didn't, silently falling back every identifier to the literal table
  name. First fix flattened the payload entirely (dropping the schema level); the actual fix
  kept in place instead is narrower and keeps the schema-then-table shape: both
  `select_payload_fields` and `get_source_identifier` use the payload's one schema entry
  directly whenever there's exactly one, and only fall back to exact-matching
  `salesforce_schema`/`salesforce_history_schema` once a second schema entry genuinely exists.
  Left here as a record of what broke and why, not as something still open.
- **Multi-org/union** — this framework is schema-shaped and ready for it (see above), but no
  union model was built or tested here (this package doesn't currently union multiple
  Salesforce orgs in staging) — only the two-schema shortcut/exact-match behavior itself was
  verified in isolation, not against a real union model's actual join/union logic.
- **Upstreaming** — `select_payload_fields`/`get_source_identifier`/`get_history_columns` are
  Salesforce-local for now. If this pattern proves out, `fivetran_utils` is the natural home
  (same precedent as the existing `add_pass_through_columns` trio), so other packages could
  adopt it.

## Final reversal: identifiers are back to 100% original main logic, no payload involvement at all

After settling on the v2-only yml-based `get_source_identifier()` design (above), the decision
changed again: drop the whole identifier-via-payload concept, not just the macro-in-yml part of
it. `get_source_identifier.sql` is deleted. `src_salesforce.yml`'s 14 `identifier:` configs and
`src_salesforce_history.yml`'s 4 are byte-identical to `main` again — plain
`var('salesforce_<table>_identifier', '<table>')`, nothing payload-driven. The payload's
`__identifier__` field is gone from every one of its 18 table entries; it now only ever carries
column rename info (canonical name → current name), never physical table names.

Rationale: physical table naming already has a working, existing convention (the per-table
`_identifier` vars) — there was never a real problem for the payload to solve here, and every
identifier design this POC tried (payload-schema-matching, yml-macro, macro-in-select_payload_fields)
was solving a problem invented by trying to unify two concerns that don't actually need to be
unified. `select_payload_fields` keeps its payload-driven column-presence/rename logic (the
actual point of this POC) and otherwise just reads from `source(source_name, table_name)`
directly, no override of any kind.

Verified against `dbt-oss 2.0.5`: `dbt parse` succeeds, all 28 models build clean against
DuckDB, the account rename/null-fill demo (`account_number = 'ACC-100234'`, `website = NULL`)
and the opportunity `description` → `Description__c` rename both still resolve correctly, and
compiled SQL's `from` clause resolves to the same `sf_<table>_data` physical tables as before —
now via the restored plain vars, not the payload.

## Vars moved to `integration_tests/vars.yml`

Per https://docs.getdbt.com/docs/build/project-variables?version=2 (dbt v1.12+/Fusion): a
project can define its `vars:` block in a dedicated `vars.yml` file instead of inline in
`dbt_project.yml`, parsed before `dbt_project.yml` itself. `integration_tests/vars.yml` now
holds the entire `vars:` block (the 18 per-table identifier vars, `salesforce_schema`/
`salesforce_history_schema`, and `salesforce__column_payload`) that used to live in
`integration_tests/dbt_project.yml`. `dbt_project.yml` keeps everything else (`seeds:`,
`dispatch:`, `clean-targets:`, `flags:`) and no longer has a `vars:` key of its own — a project
can't define `vars:` in both files at once. Verified: `dbt parse` and a full 28-model build
against DuckDB both succeed unchanged under `dbt-oss 2.0.5`.
