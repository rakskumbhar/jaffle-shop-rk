# Provider 360 - Architecture Documentation

## Overview

The Provider 360 project implements a **Medallion Architecture** (Bronze → Silver → Gold) using dbt on Snowflake. It consolidates provider data from multiple upstream systems into a unified, analytics-ready dataset.

## System Context

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SOURCE SYSTEMS                                     │
├──────────┬──────────┬───────────────┬──────────────┬─────────────────────┤
│  EMR/EHR │  Claims  │ Credentialing │ NPI Registry │ Network Management  │
└────┬─────┴────┬─────┴──────┬────────┴──────┬───────┴──────────┬──────────┘
     │          │            │              │                   │
     ▼          ▼            ▼              ▼                   ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    S3 / Cloud Storage                                      │
│  /emr/  /claims/  /credentialing/  /npi/  /network/                       │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ Snowpipe / COPY INTO
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  SNOWFLAKE_LEARNING_DB.RAW_INGESTION (Landing Zone)                       │
│  ┌──────────────────┐ ┌──────────────┐ ┌───────────────────────────┐     │
│  │ PROVIDER_MASTER  │ │  CLAIMS_RAW  │ │ PROVIDER_CREDENTIALS_RAW  │     │
│  │     _RAW         │ │              │ │                           │     │
│  └──────────────────┘ └──────────────┘ └───────────────────────────┘     │
│  ┌──────────────────┐ ┌──────────────────────────────┐                   │
│  │    NPI_RAW       │ │  NETWORK_AFFILIATIONS_RAW    │                   │
│  └──────────────────┘ └──────────────────────────────┘                   │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ dbt source()
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  BRONZE LAYER (RAW Schema) - Views                                        │
│  ┌────────────────────┐ ┌──────────────────────┐                         │
│  │ stg_emr__providers │ │ stg_claims__providers│                         │
│  └────────────────────┘ └──────────────────────┘                         │
│  ┌────────────────────┐ ┌──────────────────────┐                         │
│  │ stg_cred__providers│ │ stg_npi__registry    │                         │
│  └────────────────────┘ └──────────────────────┘                         │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ dbt ref()
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  SILVER LAYER (SILVER Schema) - Incremental Tables                        │
│  ┌──────────────────────────┐ ┌──────────────────────────────────────┐   │
│  │ int_providers__unified   │ │ int_provider_network__affiliations   │   │
│  │ (entity resolution)      │ │ (enriched with participation logic)  │   │
│  └────────────┬─────────────┘ └──────────────────────────────────────┘   │
│               ▼                                                           │
│  ┌──────────────────────────┐                                            │
│  │ int_providers__deduped   │                                            │
│  │ (ranked deduplication)   │                                            │
│  └──────────────────────────┘                                            │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ dbt ref()
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  GOLD LAYER (GOLD Schema) - Tables & Views                                │
│  ┌──────────────────┐ ┌───────────────────────┐ ┌─────────────────────┐ │
│  │  dim_provider    │ │ dim_provider_network   │ │ fct_provider_visits │ │
│  │  (SCD Type 2)    │ │ (network affiliations) │ │ (claims fact)       │ │
│  └────────┬─────────┘ └───────────────────────┘ └─────────────────────┘ │
│           │                                                               │
│  ┌────────▼─────────────────────────────────────────────────────────────┐│
│  │              provider_360_summary (One Big Table / OBT)               ││
│  │  Unified view: demographics + network + claims + credentials          ││
│  └──────────────────────────────────────────────────────────────────────┘│
│  ┌──────────────────────────┐ ┌──────────────────────────────┐          │
│  │ vw_dim_provider_current  │ │ vw_fct_provider_visits       │          │
│  │ (consumer view)          │ │ (consumer view)              │          │
│  └──────────────────────────┘ └──────────────────────────────┘          │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        DATA CONSUMERS                                      │
│  ┌────────────────┐  ┌──────────────────┐  ┌────────────────────┐        │
│  │ BI / Reporting │  │   ML Pipelines   │  │  APIs / Operational│        │
│  │ (Tableau)      │  │ (Credentialing)  │  │  (Provider Dir.)   │        │
│  └────────────────┘  └──────────────────┘  └────────────────────┘        │
└──────────────────────────────────────────────────────────────────────────┘
```

## Schema Layout

| Schema | Purpose | Materialization | Managed By |
|--------|---------|-----------------|------------|
| `RAW_INGESTION` | Landing zone for S3 files | Physical tables | Snowpipe / COPY INTO |
| `RAW` | Staging views (cast/rename) | Views | dbt (Bronze) |
| `SILVER` | Enriched, joined, deduped | Incremental tables | dbt (Silver) |
| `GOLD` | Consumer-ready analytics | Tables + Views | dbt (Gold) |
| `SNAPSHOTS` | SCD Type 2 history | Snapshot tables | dbt snapshot |

## Data Grain

| Model | Grain (One Row Per) | Primary Key |
|-------|---------------------|-------------|
| `stg_claims__providers` | Claim | `claim_id` |
| `stg_emr__providers` | Provider-facility | `emr_provider_id` |
| `stg_cred__providers` | Provider-credential | `credentialing_id` |
| `stg_npi__registry` | Provider (NPI) | `npi_number` |
| `int_providers__unified` | Provider (NPI) | `npi_number` |
| `int_providers__deduped` | Provider (NPI) | `npi_number` |
| `int_provider_network__affiliations` | Provider-network pair | `affiliation_sk` |
| `dim_provider` | Provider-version (SCD2) | `provider_sk` |
| `dim_provider_network` | Provider-network pair | `provider_network_sk` |
| `fct_provider_visits` | Claim/visit | `visit_sk` |
| `provider_360_summary` | Provider (NPI) | `npi_number` |

## Key Design Decisions

### 1. Medallion Architecture
Chosen over flat staging → mart pattern because:
- Clear separation of concerns (raw → clean → business-ready)
- Incremental processing reduces compute costs
- Easy to debug data issues at each layer

### 2. Incremental Strategy (Merge)
Silver and Gold fact tables use `incremental_strategy='merge'` with unique keys:
- Only processes new/changed rows on each run
- Handles late-arriving data and corrections via upsert
- `_loaded_at` timestamp drives incremental window

### 3. NPI as Natural Key
All provider-related models join on `npi_number` (10-digit National Provider Identifier):
- Universal healthcare provider identifier
- Stable across source systems
- Enables cross-source entity resolution without fuzzy matching

### 4. SCD Type 2 (Slowly Changing Dimensions)
`dim_provider` uses dbt snapshots with `check` strategy:
- Tracks historical changes to provider attributes
- `valid_from` / `valid_to` date windows
- `is_current` flag for easy filtering

### 5. Cluster Keys
All Silver/Gold tables are clustered on `npi_number`:
- Optimizes provider-centric queries (most common access pattern)
- Reduces micro-partition scanning for single-provider lookups

## Dependencies (DAG)

```
sources (RAW_INGESTION)
├── stg_npi__registry
│   └── int_providers__unified
│       ├── int_providers__deduped
│       │   └── provider_360_summary
│       └── snp_provider_attributes
│           └── dim_provider
│               └── vw_dim_provider_current
├── stg_cred__providers
│   └── int_providers__unified (joins)
├── stg_emr__providers
│   └── int_providers__unified (joins)
├── stg_claims__providers
│   ├── fct_provider_visits
│   │   └── vw_fct_provider_visits
│   └── provider_360_summary (visits_agg)
└── network_affiliations_raw (direct source)
    └── int_provider_network__affiliations
        ├── dim_provider_network
        └── provider_360_summary (network_agg)
```

## Exposures (Downstream Consumers)

| Consumer | Type | Dependencies |
|----------|------|--------------|
| Provider 360 Dashboard | Dashboard (Tableau) | `provider_360_summary`, `vw_dim_provider_current`, `vw_fct_provider_visits` |
| Credentialing Alert Pipeline | ML | `dim_provider` |
| Network Adequacy API | Application | `provider_360_summary`, `int_provider_network__affiliations` |

---

## DAG (Directed Acyclic Graph) - Execution Order

### Complete Lineage Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          SOURCES (RAW_INGESTION)                                 │
│                                                                                  │
│  ┌─────────────┐ ┌──────────────┐ ┌────────────────────┐ ┌─────────────────┐   │
│  │   npi_raw   │ │  claims_raw  │ │ provider_creds_raw │ │ provider_master │   │
│  └──────┬──────┘ └──────┬───────┘ └─────────┬──────────┘ └────────┬────────┘   │
│         │                │                   │                     │             │
│  ┌──────────────────────┐                                                       │
│  │network_affiliations  │                                                       │
│  │       _raw           │                                                       │
│  └──────────┬───────────┘                                                       │
└─────────────┼────────────┼───────────────────┼─────────────────────┼────────────┘
              │            │                   │                     │
              ▼            ▼                   ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      BRONZE (RAW Schema) - Views                                 │
│                                                                                  │
│         ┌────────────────────┐    ┌──────────────────────┐                      │
│         │  stg_npi__registry │    │ stg_claims__providers│                      │
│         └─────────┬──────────┘    └──────────┬───────────┘                      │
│         ┌────────────────────┐    ┌──────────────────────┐                      │
│         │stg_cred__providers │    │ stg_emr__providers   │                      │
│         └─────────┬──────────┘    └──────────┬───────────┘                      │
└───────────────────┼───────────────────────────┼─────────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    SILVER (SILVER Schema) - Incremental Tables                    │
│                                                                                  │
│    stg_npi ─────┐                                                               │
│    stg_cred ────┼──► ┌──────────────────────────┐                               │
│    stg_emr ─────┘    │  int_providers__unified   │                               │
│                      └────────────┬──────────────┘                               │
│                                   │                                              │
│                      ┌────────────┼─────────────────┐                            │
│                      ▼            ▼                  │                            │
│         ┌─────────────────────┐  ┌────────────────┐ │                            │
│         │int_providers__deduped│  │snp_provider_   │ │                            │
│         └──────────┬──────────┘  │ attributes     │ │                            │
│                    │             │ (SNAPSHOT)      │ │                            │
│                    │             └───────┬─────────┘ │                            │
│                    │                    │            │                            │
│    network_affiliations_raw ──► ┌──────────────────────────────────────┐         │
│                                 │int_provider_network__affiliations    │         │
│                                 └──────────────────┬───────────────────┘         │
└────────────────────┼───────────────────┼───────────┼────────────────────────────┘
                     │                   │           │
                     ▼                   ▼           ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      GOLD (GOLD Schema) - Tables & Views                         │
│                                                                                  │
│   ┌───────────────────┐    ┌───────────────────────┐   ┌─────────────────────┐  │
│   │    dim_provider    │    │  dim_provider_network  │   │ fct_provider_visits │  │
│   │    (SCD Type 2)    │    │  (network dim)         │   │ (claims fact)       │  │
│   └─────────┬─────────┘    └────────────────────────┘   └──────────┬──────────┘  │
│             │                                                       │             │
│             ▼                                                       ▼             │
│   ┌─────────────────────┐                              ┌────────────────────────┐│
│   │vw_dim_provider_     │                              │vw_fct_provider_visits  ││
│   │    current (view)   │                              │       (view)           ││
│   └─────────────────────┘                              └────────────────────────┘│
│                                                                                  │
│   ┌──────────────────────────────────────────────────────────────────────────┐   │
│   │                    provider_360_summary (OBT)                             │   │
│   │                                                                          │   │
│   │  Sources: int_providers__deduped + stg_claims__providers (agg)           │   │
│   │           + int_provider_network__affiliations (agg)                     │   │
│   └──────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            DATA CONSUMERS                                         │
│  ┌─────────────────────┐ ┌──────────────────────┐ ┌───────────────────────────┐ │
│  │  BI / Reporting     │ │    ML Pipelines      │ │   APIs / Operational      │ │
│  │  (Tableau)          │ │ (Credentialing Alerts)│ │  (Provider Directory)     │ │
│  └─────────────────────┘ └──────────────────────┘ └───────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### `dbt build` Execution Order (DAG-Resolved)

```
Step  Node Type    Model Name                              Schema
────  ─────────    ──────────                              ──────
 1    seed         claims_raw                              SEEDS
 2    seed         network_affiliations_raw                SEEDS
 3    seed         npi_raw                                 SEEDS
 4    seed         provider_credentials_raw                SEEDS
 5    seed         provider_master_raw                     SEEDS
 6    model        stg_npi__registry                       RAW
 7    model        stg_cred__providers                     RAW
 8    model        stg_emr__providers                      RAW
 9    model        stg_claims__providers                   RAW
10    model        int_providers__unified                  SILVER
11    model        int_provider_network__affiliations      SILVER
12    model        int_providers__deduped                  SILVER
13    snapshot     snp_provider_attributes                 SNAPSHOTS
14    model        dim_provider                            GOLD
15    model        dim_provider_network                    GOLD
16    model        fct_provider_visits                     GOLD
17    model        provider_360_summary                    GOLD
18    model        vw_dim_provider_current                 GOLD
19    model        vw_fct_provider_visits                  GOLD
20    test         (51 data quality tests)                 —
```

### Key Dependency Chains

```
Chain 1 (Provider Dimension - SCD2):
  npi_raw → stg_npi__registry ─┐
  creds_raw → stg_cred__providers ─┼─→ int_providers__unified
  emr_raw → stg_emr__providers ─┘         │
                                           ├─→ int_providers__deduped → provider_360_summary
                                           └─→ snp_provider_attributes → dim_provider → vw_dim_provider_current

Chain 2 (Claims Fact):
  claims_raw → stg_claims__providers ─┬─→ fct_provider_visits → vw_fct_provider_visits
                                      └─→ provider_360_summary (visits_agg CTE)

Chain 3 (Network Dimension):
  network_affiliations_raw → int_provider_network__affiliations ─┬─→ dim_provider_network
                                                                  └─→ provider_360_summary (network_agg CTE)
```

### Critical Path (Longest Chain)

```
npi_raw → stg_npi__registry → int_providers__unified → snp_provider_attributes → dim_provider → vw_dim_provider_current
  (6 hops — this determines minimum pipeline execution time)
```
