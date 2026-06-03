# Provider 360 - Code Walkthrough

## Project Structure

```
provider_360/
├── dbt_project.yml              # Project configuration
├── profiles.yml                 # Snowflake connection settings
├── packages.yml                 # External dbt packages
├── models/
│   ├── bronze/
│   │   ├── sources.yml          # Source definitions (RAW_INGESTION)
│   │   └── staging/
│   │       ├── claims/
│   │       │   └── stg_claims__providers.sql
│   │       ├── credentialing/
│   │       │   └── stg_cred__providers.sql
│   │       ├── emr/
│   │       │   └── stg_emr__providers.sql
│   │       └── npi/
│   │           └── stg_npi__registry.sql
│   ├── silver/
│   │   ├── schema.yml           # Silver layer tests
│   │   └── intermediate/
│   │       ├── int_providers__unified.sql
│   │       ├── int_providers__deduped.sql
│   │       └── int_provider_network__affiliations.sql
│   └── gold/
│       ├── schema.yml           # Gold layer tests
│       ├── exposures.yml        # Downstream consumer docs
│       ├── dimensions/
│       │   ├── dim_provider.sql
│       │   └── dim_provider_network.sql
│       ├── facts/
│       │   └── fct_provider_visits.sql
│       ├── obt/
│       │   └── provider_360_summary.sql
│       └── views/
│           ├── vw_dim_provider_current.sql
│           └── vw_fct_provider_visits.sql
├── macros/
│   ├── generate_schema_name.sql
│   ├── generate_surrogate_key.sql
│   └── provider_dedup.sql
├── snapshots/
│   └── snp_provider_attributes.sql
├── seeds/
│   ├── schema.yml
│   └── *.csv (development/testing data)
├── tests/
│   └── generic/
│       ├── test_no_future_dates.sql
│       ├── test_positive_amount.sql
│       └── test_valid_npi_format.sql
└── docs/
    └── (this documentation)
```

---

## Configuration Files

### dbt_project.yml

Defines materialization defaults per layer:
- **Bronze (`models/bronze/`)**: Views in `RAW` schema — lightweight, no storage cost
- **Silver (`models/silver/`)**: Incremental tables in `SILVER` schema — merge on unique keys
- **Gold (`models/gold/`)**: Tables in `GOLD` schema — full rebuilds for dimensions, incremental for facts

The `generate_schema_name` macro overrides dbt's default schema naming to use exact schema names (RAW, SILVER, GOLD) instead of appending them to the target schema.

### profiles.yml

```yaml
provider_360:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "xc57604"
      user: "RAKSKUMBHAR"
      role: ACCOUNTADMIN
      database: SNOWFLAKE_LEARNING_DB
      warehouse: COMPUTE_WH
      schema: DBT_RKUMBHAR
      threads: 8
```

Key notes:
- `account` and `user` are populated but authentication is handled by the Snowflake session in Workspaces
- `schema: DBT_RKUMBHAR` is the fallback schema — models use custom schemas via `+schema:` config
- `threads: 8` enables parallel model execution

---

## Bronze Layer (Staging Models)

### Purpose
1:1 mapping with source tables. Only performs:
- Data type casting (explicit types for downstream reliability)
- Column renaming (standardized naming conventions)
- Metadata preservation (`_loaded_at` → `_source_loaded_at`)

### Pattern (all staging models follow this)

```sql
with source as (
    select * from {{ source('source_name', 'table_name') }}
),

renamed as (
    select
        column_a::varchar(10)    as standardized_name_a,
        column_b::date           as standardized_name_b,
        _loaded_at::timestamp_ntz as _source_loaded_at
    from source
)

select * from renamed
```

### Model Details

| Model | Source | Key Columns | Notes |
|-------|--------|-------------|-------|
| `stg_npi__registry` | `npi_registry.npi_raw` | `npi_number`, `first_name`, `last_name`, `npi_status` | CMS NPI data, `status` → `npi_status` |
| `stg_cred__providers` | `credentialing.provider_credentials_raw` | `npi_number`, `specialty_code`, `credential_status` | `provider_id` → `credentialing_id` |
| `stg_emr__providers` | `emr.provider_master_raw` | `npi_number`, `facility_name`, `is_accepting_patients` | `accepting_new_patients` cast to boolean |
| `stg_claims__providers` | `claims.claims_raw` | `claim_id`, `npi_number`, `service_date`, `paid_amount` | Financial amounts cast to `number(12,2)` |

---

## Silver Layer (Intermediate Models)

### int_providers__unified

**Purpose:** Cross-source entity resolution — joins NPI, credentialing, and EMR data into one provider record.

**Logic:**
1. Reads from `stg_npi__registry` (primary — all providers must have NPI)
2. LEFT JOINs `stg_cred__providers` (latest active credential per NPI via `QUALIFY ROW_NUMBER()`)
3. LEFT JOINs `stg_emr__providers` (latest EMR record per NPI via `QUALIFY ROW_NUMBER()`)
4. Uses `GREATEST()` to compute the most recent `_source_loaded_at` across all sources

**Incremental strategy:** Merge on `npi_number`. Only processes NPIs where source `_loaded_at` exceeds the existing max.

### int_providers__deduped

**Purpose:** Applies ranking to select the most authoritative record when multiple source records exist for the same NPI.

**Logic:**
1. Reads from `int_providers__unified`
2. Generates `provider_dedup_key` surrogate key from NPI
3. Ranks by `_source_loaded_at DESC` — most recent wins
4. Filters to `_dedup_rank = 1`

**Incremental strategy:** Merge on `provider_dedup_key`. Picks up new unified records via `_unified_at` timestamp.

### int_provider_network__affiliations

**Purpose:** Enriches raw network affiliation data with current participation logic.

**Logic:**
1. Reads directly from `source('network', 'network_affiliations_raw')`
2. Generates `affiliation_sk` surrogate key
3. Computes `is_currently_participating` boolean:
   - `participation_status = 'PARTICIPATING'` AND
   - (`termination_date IS NULL` OR `termination_date > CURRENT_DATE()`)

**Incremental strategy:** Merge on `affiliation_sk`. Processes rows where `_loaded_at` exceeds existing max.

---

## Gold Layer (Consumer-Ready Models)

### dim_provider (SCD Type 2 Dimension)

**Purpose:** Historical provider dimension with change tracking.

**Source:** `snp_provider_attributes` (dbt snapshot)

**Key features:**
- `provider_sk` — surrogate key based on `npi_number + dbt_valid_from`
- `valid_from` / `valid_to` — SCD2 date windows
- `is_current` — boolean flag for filtering to latest version
- Derived fields: `full_name`, `gender_description`, `entity_type`, `npi_status_description`
- Composite flags: `is_npi_active`, `is_credentialed`, `is_fully_active`

### dim_provider_network

**Purpose:** Network affiliation dimension with tenure calculation.

**Source:** `int_provider_network__affiliations`

**Key features:**
- `tenure_days` — calculated days in network (active or until termination)
- Preserves all affiliation attributes for network adequacy analysis

### fct_provider_visits (Incremental Fact)

**Purpose:** Claims/visits fact table with financial calculations.

**Source:** `stg_claims__providers`

**Key features:**
- `visit_sk` — surrogate key from `claim_id`
- `net_paid_amount` — paid amount only for PAID claims
- `patient_responsibility` — difference between allowed and paid (for PAID claims)
- Clustered by `[npi_number, service_date]` for time-series provider queries

### provider_360_summary (One Big Table)

**Purpose:** Wide denormalized table — single row per NPI with all domain attributes.

**Sources:** Joins `int_providers__deduped` + `stg_claims__providers` (aggregated) + `int_provider_network__affiliations` (aggregated)

**Key features:**
- Provider demographics + credentials
- Claims aggregates: `total_claims`, `unique_patients`, `denial_rate_pct`
- Network aggregates: `total_networks`, `active_networks`, `active_network_list`
- `is_fully_active` composite flag (NPI active + credentialed + EMR active)

### Consumer Views

| View | Purpose |
|------|---------|
| `vw_dim_provider_current` | Filters `dim_provider` to `is_current = true` only |
| `vw_fct_provider_visits` | Pass-through view over `fct_provider_visits` for access control |

---

## Macros

### generate_schema_name

Overrides dbt's default schema concatenation. When a model specifies `+schema: GOLD`, it materializes in the `GOLD` schema directly (not `DBT_RKUMBHAR_GOLD`).

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

### generate_surrogate_key

Creates MD5-based surrogate keys from one or more columns. Handles nulls with a sentinel value to ensure consistent hashing.

```sql
{% macro generate_surrogate_key(field_list) %}
    md5(coalesce(cast(field1 as varchar), '_null_') || '|' || ...)
{%- endmacro %}
```

### provider_dedup

Reusable deduplication macro using `ROW_NUMBER()` windowing:
- `partition_key` — column to deduplicate on (default: `npi_number`)
- `order_key` — recency indicator (default: `_source_loaded_at`)

---

## Snapshots

### snp_provider_attributes

**Strategy:** `check` — monitors a list of provider attribute columns for changes.

**Tracked columns:**
- `npi_status`, `specialty_code`, `primary_taxonomy_code`
- `board_certification`, `credential_status`
- `facility_name`, `address_line_1`, `city`, `state_code`, `zip_code`
- `is_accepting_patients`, `provider_status`
- `deactivation_date`, `reactivation_date`

**Behavior:** When any tracked column changes value, the current record is closed (`dbt_valid_to` set) and a new record is inserted. Hard deletes are also tracked (`invalidate_hard_deletes=true`).

---

## Custom Tests

| Test | Purpose | Used On |
|------|---------|---------|
| `valid_npi_format` | Validates NPI is 10 digits, numeric | All `npi_number` columns |
| `no_future_dates` | Ensures dates are not in the future | `service_date` |
| `positive_amount` | Validates financial amounts >= 0 | `allowed_amount`, `paid_amount` |
