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
- `__identifier__` is a sibling key in the same table dict, not a column — it tells the model
  which physical table to read from instead of a project var.
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
- **`select_payload_fields(table_name, staging_columns)`** — the single call each model's
  `fields` CTE makes. Wraps the source/payload/relation resolution below and
  `apply_column_payload` together, emitting the complete `select ... from ...` body:
  calls `source('salesforce', table_name)` for schema/database, calls
  `normalize_column_payload` for this table's payload, rebuilds the relation via
  `api.Relation.create()` using the payload's `__identifier__` (falling back to
  `table_name` itself if absent), and generates the column list.

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
        ...
        cast(annual_revenue as {{ dbt.type_numeric() }}) as annual_revenue,   -- only where a real type override is needed
        description as account_description,                                   -- rename via plain `as`
        id as account_id,
        ...
        {{ fivetran_utils.fill_pass_through_columns('salesforce__account_pass_through_columns') }}

    from fields
    where coalesce(_fivetran_active, true)
)

select *
from final
where not coalesce(is_deleted, false)
```

`final` is hand-written SQL, not a macro call per column — bare column, `x as alias`, or
`cast(x as type) as alias` only where a real type override is needed (e.g. money fields cast
to numeric). This is deliberately the same shape as e.g. `stg_google_ads__campaign_stats`:
`fields` resolves/fills columns via a macro, `final` is plain SQL. `get_*_columns()` macros
are unchanged from `main` except for the removed `add_renamed_columns()` call — they're still
the single source of truth for datatypes used to null-fill absent columns.

`opportunity` keeps its extra `calculated` CTE (date-diff logic) unchanged, sourced from
`final` as before.

## What got deleted

- `macros/staging/add_renamed_columns.sql`, `coalesce_rename.sql`, `column_list_to_dict.sql` —
  the camelCase-guessing/coalescing machinery this POC replaces. Nothing calls them anymore.
- The 14 per-table `identifier: "{{ var('salesforce_<table>_identifier', '<table>') }}"`
  overrides in `models/salesforce/staging/src_salesforce.yml` — redundant now that the FROM
  relation is built from the payload's `__identifier__` instead.
- The source-level freshness config (`loaded_at_field` / `warn_after` / `error_after`) and the
  10 per-table `config: freshness: null` overrides that existed only to opt back out of it.

**Removing the identifiers means `dbt source freshness` and catalog/docs generation for this
source are no longer meaningful** — they'd resolve against the literal default table name
(e.g. `account`), not whatever a real customer's physical table is actually called, since that
mapping only exists inside the payload var now. That's why freshness config came out in the
same pass rather than being left dangling. If a real implementation of this design ships, it
needs its own answer for freshness/catalog (e.g. quickstart-side checks, or a different
mechanism entirely) — this POC doesn't attempt one.

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
- Identifier resolution: confirmed the `FROM` clause resolves to the payload's
  `__identifier__` (e.g. `sf_account_data`) via `api.Relation.create`, not a project var.

## Open questions / follow-ups (not resolved by this POC)

- **How the real quickstart runtime supplies this var per customer** — this POC hand-authors
  it in `integration_tests/dbt_project.yml`; production wiring is undesigned.
- **Freshness/catalog/docs** — see above; needs its own design if this ships.
- **Multi-org/union** — the schema-keyed structure should extend to per-`source_relation`
  payloads, but no union model was built or tested here (this package doesn't currently union
  multiple Salesforce orgs in staging).
- **Upstreaming** — `apply_column_payload`/`normalize_column_payload` are Salesforce-local for
  now. If this pattern proves out, `fivetran_utils` is the natural home (same precedent as the
  existing `add_pass_through_columns` trio), so other packages could adopt it.
