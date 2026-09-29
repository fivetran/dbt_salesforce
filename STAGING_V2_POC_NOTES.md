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
- `__identifier__` is a sibling key in the same table dict, not a column — it can override
  which physical table to read from, on top of the yml/var-configured identifier (see below).
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
  `fields` CTE makes. Wraps the source/payload/relation resolution and `apply_column_payload`
  together, emitting the complete `select ... from ...` body: calls
  `source('salesforce', table_name)` for schema/database (and the yml tie described below),
  calls `normalize_column_payload` for this table's payload, and rebuilds the relation via
  `api.Relation.create()` using the payload's `__identifier__` when present, falling back to
  `source(...).identifier` (the yml/var-configured one) otherwise — never a bare literal
  `table_name`.

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

That's it. An earlier pass through this POC also deleted the 14 per-table `identifier:`
overrides and the freshness config in `src_salesforce.yml`, reasoning that the FROM relation
no longer needed them since it's built from the payload's `__identifier__`. That was wrong —
see the next section — and both were put back.

## The identifier still has to live in `src_salesforce.yml`, not just the payload

`select_payload_fields` still calls `source('salesforce', table_name)`, and that's not
incidental — it's the only tie back to `src_salesforce.yml` dbt itself understands. It's what
makes this model show up as a dependent of the `salesforce.account` source node for
`dbt run --select +stg_salesforce__account`, `dbt list`, and the lineage graph in `dbt docs`.
Schema and database still come from there too (`table_source.schema` / `.database`, driven by
the source-level `schema:`/`database:` config).

What briefly went missing: the per-table `identifier:` config is also the *only* place dbt's
own tooling — `dbt source freshness`, `dbt docs generate`'s catalog, anything that calls
`{{ source('salesforce','account') }}` directly instead of going through
`select_payload_fields` — learns the real physical table name. The payload's `__identifier__`
is invisible to all of that; it only exists inside a Jinja var evaluated at compile time
for our own macro. Deleting the yml identifiers left `source('salesforce','account')`
resolving to the literal default `account`, while the model actually queried whatever the
payload said — two different physical tables, with nothing tying them together except
convention. So both the `identifier:` overrides and the freshness config (which depends on
that same identifier being configured) are back exactly as they were on `main`.

With both present, the payload's `__identifier__` is now an **optional override on top of**
the yml-configured one, not a replacement for it: `select_payload_fields` falls back to
`table_source.identifier` (the yml/var-resolved one) when a table is missing from the payload
or its dict has no `__identifier__`, rather than a bare literal `table_name`. Verified with the
payload emptied out entirely (`salesforce__column_payload: {}`): the model still builds, and
the compiled `FROM` correctly resolves to `sf_account_data` (the var-configured identifier),
not `account` and not an error.

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
  `__identifier__` (e.g. `sf_account_data`) via `api.Relation.create` when present, and falls
  back to the yml/var-configured identifier (not a bare literal) when the payload is empty.

## Open questions / follow-ups (not resolved by this POC)

- **How the real quickstart runtime supplies this var per customer** — this POC hand-authors
  it in `integration_tests/dbt_project.yml`; production wiring is undesigned.
- **Identifier lives in two places now** — the yml/var identifier and the payload's
  `__identifier__` describe the same real-world table but aren't structurally tied together;
  nothing stops them from drifting apart for a given customer. Whether that's acceptable (the
  yml one is only a fallback / doc-facing value) or whether `__identifier__` should be dropped
  entirely now that the yml identifier is back is worth deciding before this goes further.
- **Multi-org/union** — the schema-keyed structure should extend to per-`source_relation`
  payloads, but no union model was built or tested here (this package doesn't currently union
  multiple Salesforce orgs in staging).
- **Upstreaming** — `apply_column_payload`/`normalize_column_payload` are Salesforce-local for
  now. If this pattern proves out, `fivetran_utils` is the natural home (same precedent as the
  existing `add_pass_through_columns` trio), so other packages could adopt it.
