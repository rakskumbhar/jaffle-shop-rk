# Provider 360 - Incremental Processing

## Overview

This project uses dbt's **incremental materialization** with Snowflake's **merge** strategy to efficiently process only new or changed data on each run, avoiding costly full-table rebuilds.

## How Incremental Models Work

### First Run (Full Refresh)

On the first execution (or `--full-refresh`), all rows from the source are processed:

```
Source Table (1M rows) → Full scan → Target Table (1M rows)
```

### Subsequent Runs (Incremental)

Only rows newer than the last processed timestamp are scanned:

```
Source Table (1M + 5K new rows) → Scan 5K new rows only → MERGE into Target Table
```

---

## Incremental Pattern Used

All incremental models follow this pattern:

```sql
{{ config(
    materialized='incremental',
    unique_key='<surrogate_key>',
    incremental_strategy='merge',
    cluster_by=['npi_number']
) }}

with source as (
    select * from {{ ref('upstream_model') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(_source_loaded_at) from {{ this }})
    {% endif %}
),
...
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `is_incremental()` | Returns `true` on non-first runs (when target table exists) |
| `{{ this }}` | References the target table itself |
| `unique_key` | Column(s) used to match existing rows for merge/upsert |
| `incremental_strategy='merge'` | Uses Snowflake MERGE (upsert: insert new, update existing) |

---

## Model-by-Model Incremental Logic

### int_providers__unified

```sql
-- Incremental filter: only process NPIs with newer source data
from {{ ref('stg_npi__registry') }}
{% if is_incremental() %}
    where _source_loaded_at > (select max(_source_loaded_at) from {{ this }})
{% endif %}
```

| Property | Value |
|----------|-------|
| **Unique key** | `npi_number` |
| **Incremental filter** | `_source_loaded_at > max existing` |
| **Merge behavior** | Existing NPI → UPDATE all columns; New NPI → INSERT |

### int_providers__deduped

```sql
-- Picks up newly unified records
from {{ ref('int_providers__unified') }}
{% if is_incremental() %}
    where _unified_at > (select max(_unified_at) from {{ this }})
{% endif %}
```

| Property | Value |
|----------|-------|
| **Unique key** | `provider_dedup_key` (MD5 of NPI) |
| **Incremental filter** | `_unified_at > max existing` |
| **Merge behavior** | Re-ranks if a newer source record arrives |

### int_provider_network__affiliations

```sql
-- Reads directly from source (not staging view)
from {{ source('network', 'network_affiliations_raw') }}
{% if is_incremental() %}
    where _loaded_at > (select max(_source_loaded_at) from {{ this }})
{% endif %}
```

| Property | Value |
|----------|-------|
| **Unique key** | `affiliation_sk` (MD5 of affiliation ID) |
| **Incremental filter** | `_loaded_at > max existing` |
| **Merge behavior** | Updated affiliations overwrite; new affiliations insert |

### fct_provider_visits

```sql
-- Claims fact table
from {{ ref('stg_claims__providers') }}
{% if is_incremental() %}
    where _source_loaded_at > (select max(_source_loaded_at) from {{ this }})
{% endif %}
```

| Property | Value |
|----------|-------|
| **Unique key** | `visit_sk` (MD5 of claim_id) |
| **Incremental filter** | `_source_loaded_at > max existing` |
| **Merge behavior** | Corrected claims update; new claims insert |
| **Cluster by** | `[npi_number, service_date]` |

---

## Timestamp Flow

Understanding how timestamps propagate through layers:

```
RAW_INGESTION._loaded_at (set by Snowpipe/COPY INTO at ingestion time)
    │
    ▼ (renamed in staging)
RAW.stg_*._source_loaded_at
    │
    ▼ (carried through or computed)
SILVER.int_*._source_loaded_at / _unified_at / _enriched_at
    │
    ▼ (carried or new timestamp)
GOLD.fct_*._source_loaded_at + _dbt_loaded_at
```

| Timestamp Column | Set By | Purpose |
|------------------|--------|---------|
| `_loaded_at` | Snowpipe / COPY INTO | When data arrived in Snowflake |
| `_source_loaded_at` | Staging (renamed) | Consistent name for incremental filters |
| `_unified_at` | `int_providers__unified` | When entity resolution ran |
| `_enriched_at` | Silver enrichment models | When business logic was applied |
| `_dbt_loaded_at` | Gold models | When consumer-ready table was built |

---

## When to Use --full-refresh

Use `dbt run --full-refresh` when:

| Scenario | Why Full Refresh |
|----------|-----------------|
| Schema change (add/remove columns) | Merge can't handle DDL changes |
| Incremental logic bug fix | Existing data was built with wrong logic |
| Unique key change | Merge target changes, existing data orphaned |
| Initial deployment to new environment | No target tables exist yet |
| Backfill after extended downtime | Gap in `_loaded_at` may miss records |

```bash
# Full refresh specific model + downstream
dbt run --full-refresh --select +provider_360_summary

# Full refresh entire project
dbt run --full-refresh
```

---

## Handling Edge Cases

### Late-Arriving Data

**Scenario:** A claim from Jan 15 arrives on Jan 20 with `_loaded_at = Jan 20`.

**Behavior:** The incremental filter picks it up (Jan 20 > last max). The merge upserts by `claim_id`, so:
- If the claim_id is new → INSERT
- If it's a correction to an existing claim → UPDATE

### Duplicate Data from Source

**Scenario:** Same file is loaded twice via Snowpipe.

**Behavior:** 
- `_loaded_at` differs (second load has newer timestamp)
- Incremental filter picks up the duplicate
- Merge on `unique_key` → UPDATE (no duplicate row created)
- Net result: latest version preserved, no duplicates in target

### Source System Corrections

**Scenario:** Provider changes address; EMR sends corrected record.

**Behavior:**
1. New record lands in `RAW_INGESTION` with new `_loaded_at`
2. `stg_emr__providers` (view) shows both old and new
3. `int_providers__unified` incremental picks up the NPI (newer `_loaded_at`)
4. Merge on `npi_number` → UPDATE with corrected address
5. Snapshot captures the change (old record closed, new record opened)

---

## Performance Considerations

### Cluster Keys

All incremental tables are clustered on `npi_number`:
```sql
cluster_by=['npi_number']
```

This optimizes:
- The MERGE operation (matching existing rows by NPI)
- Downstream queries that filter by provider

### Incremental Window Efficiency

The `WHERE _loaded_at > (SELECT MAX(...))` pattern is efficient because:
1. Snowflake computes the MAX via metadata (no table scan)
2. The filter prunes micro-partitions using clustering metadata
3. Only matching partitions are scanned

### Monitoring Incremental Runs

Check how much data each run processes:
```sql
-- View run results
SELECT * FROM SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.dbt_run_results
ORDER BY completed_at DESC;

-- Or check row counts
SELECT 'SILVER.INT_PROVIDERS__UNIFIED' as model,
       COUNT(*) as total_rows,
       COUNT(CASE WHEN _unified_at > DATEADD('day', -1, CURRENT_TIMESTAMP()) THEN 1 END) as rows_last_day
FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED;
```

---

## Incremental vs Table vs View Decision Matrix

| Factor | View | Table | Incremental |
|--------|------|-------|-------------|
| Storage cost | None | Full table | Full table |
| Query speed | Recomputes each time | Fast (precomputed) | Fast (precomputed) |
| Build time | Instant (DDL only) | Full rebuild each run | Processes only new rows |
| Use case | <100K rows, staging | Dimensions, reference | Large facts, event data |
| This project | Bronze staging | Gold dimensions, OBT | Silver layer, Gold facts |
