# Provider 360 - Testing New Data

## Overview

This guide covers how to validate new data as it flows through the pipeline, including:
- Pre-load validation
- Post-load verification
- dbt test execution
- Manual spot-checks
- Regression testing after changes

---

## 1. Pre-Load Validation (Before Data Enters Snowflake)

### Source File Checks

Before loading into `RAW_INGESTION`, validate source files:

| Check | How | Expected |
|-------|-----|----------|
| File exists in S3 | `LIST @PROVIDER_360_STAGE/claims/` | Files present for today |
| File size reasonable | Compare to historical average | ±20% of prior day |
| Schema matches | Check column headers | Matches landing table DDL |
| No empty files | File size > 0 | All files have data |

```sql
-- Check what's available in stage
LIST @SNOWFLAKE_LEARNING_DB.RAW_INGESTION.PROVIDER_360_STAGE/claims/;

-- Validate file structure before loading (dry run)
SELECT $1, $2, $3
FROM @SNOWFLAKE_LEARNING_DB.RAW_INGESTION.PROVIDER_360_STAGE/claims/
(FILE_FORMAT => 'SNOWFLAKE_LEARNING_DB.RAW_INGESTION.PARQUET_FORMAT')
LIMIT 5;
```

---

## 2. Post-Load Verification (After COPY INTO / Snowpipe)

### Row Count Validation

```sql
-- Check today's loaded rows per source
SELECT
    'CLAIMS_RAW' as source_table,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN _loaded_at::date = CURRENT_DATE() THEN 1 END) as rows_loaded_today,
    MAX(_loaded_at) as latest_load_timestamp
FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW

UNION ALL

SELECT
    'PROVIDER_MASTER_RAW',
    COUNT(*),
    COUNT(CASE WHEN _loaded_at::date = CURRENT_DATE() THEN 1 END),
    MAX(_loaded_at)
FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.PROVIDER_MASTER_RAW

UNION ALL

SELECT
    'NPI_RAW',
    COUNT(*),
    COUNT(CASE WHEN _loaded_at::date = CURRENT_DATE() THEN 1 END),
    MAX(_loaded_at)
FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.NPI_RAW

UNION ALL

SELECT
    'PROVIDER_CREDENTIALS_RAW',
    COUNT(*),
    COUNT(CASE WHEN _loaded_at::date = CURRENT_DATE() THEN 1 END),
    MAX(_loaded_at)
FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.PROVIDER_CREDENTIALS_RAW

UNION ALL

SELECT
    'NETWORK_AFFILIATIONS_RAW',
    COUNT(*),
    COUNT(CASE WHEN _loaded_at::date = CURRENT_DATE() THEN 1 END),
    MAX(_loaded_at)
FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.NETWORK_AFFILIATIONS_RAW;
```

### Pipe Status Check

```sql
-- Verify Snowpipe processing
SELECT pipe_name, last_ingested_file_name, last_ingested_file_row_count
FROM TABLE(INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
    DATE_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP()),
    PIPE_NAME => 'SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_PIPE'
));

-- Check for pipe errors
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW',
    START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
WHERE status = 'LOAD_FAILED';
```

---

## 3. dbt Test Execution

### Run All Tests

```bash
# Full test suite (51 tests)
dbt test --project-dir provider_360
```

### Run Tests by Layer

```bash
# Bronze tests only (source freshness)
dbt source freshness --project-dir provider_360

# Silver layer tests
dbt test --project-dir provider_360 --select tag:silver

# Gold layer tests
dbt test --project-dir provider_360 --select tag:gold
```

### Run Tests for Specific Model

```bash
# Test a single model
dbt test --project-dir provider_360 --select int_providers__unified

# Test a model and all its downstream dependents
dbt test --project-dir provider_360 --select int_providers__unified+
```

### Test Categories

| Category | Test | Models Applied To |
|----------|------|-------------------|
| **Not Null** | `not_null` | All primary keys, required fields |
| **Uniqueness** | `unique` | All surrogate keys, natural keys |
| **Referential Integrity** | `relationships` | Cross-model NPI references |
| **Valid Values** | `accepted_values` | Status fields, enum columns |
| **Custom: NPI Format** | `valid_npi_format` | All `npi_number` columns |
| **Custom: No Future Dates** | `no_future_dates` | `service_date` |
| **Custom: Positive Amount** | `positive_amount` | `allowed_amount`, `paid_amount` |

---

## 4. Manual Spot-Check Queries

### After Daily Run - Quick Validation

```sql
-- 1. Check provider_360_summary freshness
SELECT
    COUNT(*) as total_providers,
    MAX(_dbt_loaded_at) as last_build_time,
    DATEDIFF('minute', MAX(_dbt_loaded_at), CURRENT_TIMESTAMP()) as minutes_since_build
FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY;

-- 2. Verify new claims flowed through
SELECT
    MAX(service_date) as latest_service_date,
    COUNT(CASE WHEN _dbt_loaded_at::date = CURRENT_DATE() THEN 1 END) as claims_built_today
FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS;

-- 3. Check for orphaned providers (in Gold but not in source)
SELECT g.npi_number
FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY g
LEFT JOIN SNOWFLAKE_LEARNING_DB.RAW_INGESTION.NPI_RAW n
  ON g.npi_number = n.npi_number
WHERE n.npi_number IS NULL;
```

### Data Consistency Checks

```sql
-- Cross-layer row count comparison
SELECT
    'RAW (staging views)' as layer,
    (SELECT COUNT(DISTINCT npi_number) FROM SNOWFLAKE_LEARNING_DB.RAW.STG_NPI__REGISTRY) as distinct_npis

UNION ALL

SELECT
    'SILVER (unified)',
    (SELECT COUNT(*) FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED)

UNION ALL

SELECT
    'SILVER (deduped)',
    (SELECT COUNT(*) FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__DEDUPED)

UNION ALL

SELECT
    'GOLD (360 summary)',
    (SELECT COUNT(*) FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY);
```

```sql
-- Financial reconciliation
SELECT
    'Source (staging)' as layer,
    SUM(allowed_amount) as total_allowed,
    SUM(paid_amount) as total_paid,
    COUNT(*) as claim_count
FROM SNOWFLAKE_LEARNING_DB.RAW.STG_CLAIMS__PROVIDERS

UNION ALL

SELECT
    'Gold (fact table)',
    SUM(allowed_amount),
    SUM(paid_amount),
    COUNT(*)
FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS;
```

---

## 5. Testing New Source Data (Simulation)

### Step 1: Prepare Test Data

```sql
-- Insert test records into RAW_INGESTION (simulating a new S3 load)
INSERT INTO SNOWFLAKE_LEARNING_DB.RAW_INGESTION.NPI_RAW VALUES
    ('9999999999', 'Test', 'Provider', 'MD', 'M', '1', 'Y',
     '2024-01-01', '2024-06-01', NULL, NULL, 'A', CURRENT_TIMESTAMP());

INSERT INTO SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW VALUES
    ('CLM-TEST-001', '9999999999', 'PAT-TEST', '2024-06-01', '99213',
     'Z00.00', 150.00, 120.00, 'PAID', 'IN_NETWORK', CURRENT_TIMESTAMP());
```

### Step 2: Run Incremental

```bash
dbt run --project-dir provider_360
```

### Step 3: Verify Test Data Propagated

```sql
-- Check it reached Gold
SELECT *
FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
WHERE npi_number = '9999999999';

-- Check claims fact
SELECT *
FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS
WHERE npi_number = '9999999999';
```

### Step 4: Run Tests

```bash
dbt test --project-dir provider_360
```

### Step 5: Cleanup Test Data

```sql
-- Remove test records
DELETE FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.NPI_RAW WHERE npi_number = '9999999999';
DELETE FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW WHERE claim_id = 'CLM-TEST-001';

-- Full refresh to remove from downstream
dbt run --project-dir provider_360 --full-refresh
```

---

## 6. Regression Testing After Code Changes

### Before Merging Changes

```bash
# 1. Compile to check syntax
dbt compile --project-dir provider_360

# 2. Run changed models only
dbt run --project-dir provider_360 --select state:modified+

# 3. Test changed models and downstream
dbt test --project-dir provider_360 --select state:modified+
```

### Compare Before/After

```sql
-- Snapshot row counts before change
CREATE TEMPORARY TABLE row_counts_before AS
SELECT 'UNIFIED' as model, COUNT(*) as cnt FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED
UNION ALL SELECT 'DEDUPED', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__DEDUPED
UNION ALL SELECT 'SUMMARY', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY;

-- After dbt run --full-refresh, compare
SELECT b.model, b.cnt as before_count, a.cnt as after_count, a.cnt - b.cnt as diff
FROM row_counts_before b
JOIN (
    SELECT 'UNIFIED' as model, COUNT(*) as cnt FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED
    UNION ALL SELECT 'DEDUPED', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__DEDUPED
    UNION ALL SELECT 'SUMMARY', COUNT(*) FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
) a ON b.model = a.model;
```

---

## 7. Alerting on Test Failures

### Task-Based Alerting

```sql
-- Create an alert when tests fail
CREATE OR REPLACE ALERT SNOWFLAKE_LEARNING_DB.DBT_RKUMBHAR.DBT_TEST_FAILURE_ALERT
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 45 6 * * * UTC'  -- Run after daily test task
  IF (EXISTS (
      SELECT 1 FROM SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TASK_HISTORY
      WHERE name = 'DAILY_DBT_TEST'
        AND state = 'FAILED'
        AND scheduled_time > DATEADD('day', -1, CURRENT_TIMESTAMP())
  ))
  THEN
    CALL SYSTEM$SEND_EMAIL(
      'provider_360_alerts',
      'data-team@example.com',
      'Provider 360 dbt Test Failure',
      'dbt tests failed in the daily run. Check task history for details.'
    );
```

---

## 8. Test Data Quality Summary Dashboard Query

```sql
-- Comprehensive quality summary
SELECT
    'Total Providers' as metric, COUNT(*)::VARCHAR as value
    FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY
UNION ALL
SELECT 'Fully Active Providers', COUNT(*)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.GOLD.PROVIDER_360_SUMMARY WHERE is_fully_active = TRUE
UNION ALL
SELECT 'Providers Missing Credentials', COUNT(*)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.SILVER.INT_PROVIDERS__UNIFIED WHERE credential_status IS NULL
UNION ALL
SELECT 'Total Claims', COUNT(*)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS
UNION ALL
SELECT 'Denied Claims', COUNT(*)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.GOLD.FCT_PROVIDER_VISITS WHERE claim_status = 'DENIED'
UNION ALL
SELECT 'Active Network Affiliations', COUNT(*)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.GOLD.DIM_PROVIDER_NETWORK WHERE is_currently_participating = TRUE
UNION ALL
SELECT 'Latest Data Load', MAX(_loaded_at)::VARCHAR
    FROM SNOWFLAKE_LEARNING_DB.RAW_INGESTION.CLAIMS_RAW;
```
