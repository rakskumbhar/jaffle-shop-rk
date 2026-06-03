# Provider 360 - Operations Guide

## Daily Operations

### Standard Daily Run

The daily operational cycle:

```
6:00 AM  - S3 files land (Snowpipe auto-ingests OR scheduled COPY INTO)
6:30 AM  - dbt run (incremental)
6:35 AM  - dbt test (data quality validation)
6:40 AM  - dbt snapshot (SCD Type 2 capture)
7:00 AM  - Data available to consumers
```

### dbt Commands Reference

```bash
# Standard incremental run (daily)
dbt run --project-dir provider_360

# Run with full refresh (after schema changes or logic fixes)
dbt run --project-dir provider_360 --full-refresh

# Run specific model and its upstream dependencies
dbt run --project-dir provider_360 --select +provider_360_summary

# Run only Gold layer models
dbt run --project-dir provider_360 --select tag:gold

# Run tests
dbt test --project-dir provider_360

# Run snapshot (SCD Type 2)
dbt snapshot --project-dir provider_360

# Compile without executing (validate SQL)
dbt compile --project-dir provider_360

# Seed development data (only for dev/test environments)
dbt seed --project-dir provider_360
```

---

## Deployment (Snowflake-Native)

### Deploy as Snowflake DBT PROJECT

```sql
-- Deploy from workspace
CREATE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360
  FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/provider_360';

-- Execute the project
EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'run';

-- Execute with full refresh
EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'run --full-refresh';

-- Execute tests
EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'test';
```

### Schedule with Tasks

```sql
-- Daily incremental run at 6:30 AM UTC
CREATE OR REPLACE TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_RUN
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 30 6 * * * UTC'
AS
  EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'run';

-- Daily tests after run
CREATE OR REPLACE TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_TEST
  WAREHOUSE = COMPUTE_WH
  AFTER SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_RUN
AS
  EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'test';

-- Daily snapshot after tests
CREATE OR REPLACE TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_SNAPSHOT
  WAREHOUSE = COMPUTE_WH
  AFTER SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_TEST
AS
  EXECUTE DBT PROJECT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.PROVIDER_360 ARGS = 'snapshot';

-- Enable the task tree
ALTER TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_SNAPSHOT RESUME;
ALTER TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_TEST RESUME;
ALTER TASK SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DAILY_DBT_RUN RESUME;
```

---

## Monitoring

### Check Model Freshness

```sql
-- Check when each Gold table was last updated
SELECT table_name, last_altered
FROM SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'GOLD'
ORDER BY last_altered DESC;
```

### Check Source Freshness

```bash
dbt source freshness --project-dir provider_360
```

This validates that `_loaded_at` in source tables is within the SLA defined in `sources.yml`:
- Claims: warn after 24h, error after 72h
- EMR: warn after 12h, error after 48h
- Network: warn after 24h, error after 72h
- NPI: warn after 24h, error after 72h

### Check Row Counts

```sql
-- Compare row counts across layers
SELECT 'RAW_INGESTION.CLAIMS_RAW' as table_name, COUNT(*) as rows FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW
UNION ALL
SELECT 'RAW.STG_CLAIMS__PROVIDERS', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.RAW.STG_CLAIMS__PROVIDERS
UNION ALL
SELECT 'GOLD.FCT_PROVIDER_VISITS', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS;
```

### Check for Data Quality Issues

```sql
-- Providers missing credentials
SELECT npi_number, first_name, last_name
FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED
WHERE credential_status IS NULL;

-- Claims with zero amounts
SELECT claim_id, npi_number, allowed_amount, paid_amount
FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS
WHERE allowed_amount = 0 OR paid_amount = 0;

-- Providers in NPI but not in EMR
SELECT u.npi_number, u.first_name, u.last_name
FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED u
WHERE u.facility_name IS NULL;
```

---

## Troubleshooting

### Common Issues

#### 1. "Relation does not exist"

**Cause:** Target schema/table was dropped externally.
**Fix:**
```bash
dbt run --project-dir provider_360 --full-refresh --select model_name
```

#### 2. Incremental model has stale data

**Cause:** Source loaded data with old `_loaded_at` (backfill scenario).
**Fix:**
```bash
# Full refresh the affected model and downstream
dbt run --project-dir provider_360 --full-refresh --select +model_name
```

#### 3. Snapshot not capturing changes

**Cause:** Tracked columns haven't changed, or upstream model hasn't been refreshed.
**Fix:**
```bash
# Ensure upstream is fresh first
dbt run --project-dir provider_360 --select int_providers__unified
# Then run snapshot
dbt snapshot --project-dir provider_360
```

#### 4. Schema mismatch after column addition

**Cause:** New column added to source but `on_schema_change` not handling it.
**Fix:**
```bash
# Silver models have on_schema_change: sync_all_columns
# Just run with full refresh
dbt run --project-dir provider_360 --full-refresh --select model_name
```

#### 5. Tests failing after data load

**Cause:** Bad data in source system.
**Investigate:**
```bash
# Run specific failing test in isolation
dbt test --project-dir provider_360 --select test_name

# Check the compiled SQL
# Look in provider_360/target/compiled/... for the actual SQL executed
```

---

## Rollback Procedures

### Revert a Bad Run

Snowflake's Time Travel allows reverting tables:

```sql
-- Revert Gold table to state before bad run (within retention period)
CREATE OR REPLACE TABLE SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
  CLONE SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
  AT (OFFSET => -3600);  -- 1 hour ago

-- Or revert to specific timestamp
CREATE OR REPLACE TABLE SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
  CLONE SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
  AT (TIMESTAMP => '2026-06-01 06:00:00'::TIMESTAMP);
```

### Full Environment Reset

```bash
# Drop all dbt-managed objects and rebuild from scratch
dbt run --project-dir provider_360 --full-refresh
dbt snapshot --project-dir provider_360
dbt test --project-dir provider_360
```

---

## Cost Management

### Warehouse Sizing Recommendations

| Operation | Recommended Size | Frequency |
|-----------|-----------------|-----------|
| Daily incremental run | X-Small | Daily |
| Full refresh | Small | Weekly/on-demand |
| dbt test | X-Small | Daily (after run) |
| Snapshot | X-Small | Daily |

### Auto-Suspend Configuration

```sql
ALTER WAREHOUSE COMPUTE_WH SET
  AUTO_SUSPEND = 60        -- Suspend after 60s idle
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 1;
```

### Monitor Credit Usage

```sql
SELECT warehouse_name,
       SUM(credits_used) as total_credits,
       COUNT(*) as query_count
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND warehouse_name = 'COMPUTE_WH'
GROUP BY 1;
```
