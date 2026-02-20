# Healthcare MLOps Demo - Snowflake Feature Store

A comprehensive MLOps demonstration using Snowflake's native ML capabilities to build a **30-day hospital readmission risk prediction** system.

## Overview

This demo showcases the full MLOps lifecycle using Snowflake:

| Notebook | Topic | Key Features |
|----------|-------|--------------|
| 01 | Data Ingestion & Pipeline | Internal stages, Streams, Dynamic Tables |
| 02 | Feature Engineering | Feature Store, Entities, Feature Views |
| 03 | Model Training | Dataset generation, XGBoost, Model Registry |
| 04 | Inference & Monitoring | Batch/real-time inference, drift detection |

## Business Use Case

Hospital readmissions within 30 days are a key quality metric. CMS penalizes hospitals with excess readmissions, making early identification of high-risk patients critical for:
- Reducing costs
- Improving patient outcomes
- Avoiding regulatory penalties

---

## Demo Setup Flow

### Phase 1: Bootstrap (5 min)

Run `00a_bootstrap.sql` in a **Snowsight Worksheet** to create the database and connect the Git repository:

```sql
-- Run in Snowsight Worksheet
-- This creates the database and connects the Git repo
```

The bootstrap script:
- Creates `HEALTHCARE_MLOPS` database
- Creates `ML` schema
- Sets up GitHub API integration (if needed)
- Connects this Git repository to Snowflake

### Phase 2: Explore Git Integration in Snowsight (5 min)

After running the bootstrap:

1. Navigate to: **Data → Databases → HEALTHCARE_MLOPS → ML → Git Repositories → NOTEBOOKS_REPO**
2. Browse the repository files in the Snowsight UI
3. Show the notebooks and SQL files synced from GitHub

### Phase 3: Run Main Setup (10 min)

Open `00b_setup.sql` from the Git repository and run it to create:
- Remaining schemas (RAW, CURATED, FEATURE_STORE, STAGING)
- Warehouse
- Internal stage for data files
- Raw tables (PATIENTS, ENCOUNTERS, CONDITIONS)
- Streams for CDC
- Roles and privileges

### Phase 4: Upload Data & Run Notebooks (90 min)

1. **Upload data files** to the internal stage
2. **Run notebooks** in order: 01 → 02 → 03 → 04

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                      DATA PIPELINE (Notebook 1)                        │
├────────────────────────────────────────────────────────────────────────┤
│  Internal Stage → RAW Tables → Streams → Dynamic Tables (Bronze/Silver)│
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      FEATURE STORE (Notebook 2)                        │
├────────────────────────────────────────────────────────────────────────┤
│  Entities (PATIENT, ENCOUNTER) → Feature Views → Automated Refresh     │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      MODEL REGISTRY (Notebook 3)                       │
├────────────────────────────────────────────────────────────────────────┤
│  Training Dataset → XGBoost Model → Versioned Registry → Lineage      │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      INFERENCE (Notebook 4)                            │
├────────────────────────────────────────────────────────────────────────┤
│  Batch Scoring → Real-time Inference → Model Monitoring → Alerts      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- Snowflake account with:
  - ACCOUNTADMIN role (for initial setup)
  - Snowpark ML enabled
  - Snowflake Notebooks access

---

## Detailed Setup Instructions

### Step 1: Run Bootstrap Script

In a Snowsight SQL Worksheet, open and run `00a_bootstrap.sql`:

```sql
-- Creates database, ML schema, and connects Git repo
-- See 00a_bootstrap.sql for full script
```

### Step 2: Run Main Setup Script

Open `00b_setup.sql` from the Git repository in Snowsight and run it.

### Step 3: Upload Data to Internal Stage

**Option A: Using SnowSQL**
```sql
PUT file:///path/to/data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/;
PUT file:///path/to/data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/;
PUT file:///path/to/data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/;
```

**Option B: Using Snowflake CLI**
```bash
snow stage copy data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/
snow stage copy data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/
snow stage copy data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/
```

### Step 4: Run Demo Notebooks

Run each notebook in order from Snowsight:

1. `notebooks/01_data_ingestion_pipeline.ipynb`
2. `notebooks/02_feature_engineering.ipynb`
3. `notebooks/03_model_training.ipynb`
4. `notebooks/04_inference_monitoring.ipynb`

---

## Syncing Git Updates

After making changes and pushing to GitHub:

```sql
ALTER GIT REPOSITORY HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO FETCH;
```

---

## Data Dictionary

### Patients
| Column | Description |
|--------|-------------|
| PATIENT_ID | Unique patient identifier |
| BIRTH_DATE | Date of birth |
| GENDER | M/F |
| RACE/ETHNICITY | Demographics |
| INCOME | Annual income |
| HEALTHCARE_EXPENSES | Total healthcare costs |
| HEALTHCARE_COVERAGE | Insurance coverage amount |

### Encounters
| Column | Description |
|--------|-------------|
| ENCOUNTER_ID | Unique encounter identifier |
| PATIENT_ID | Patient reference |
| START_DATETIME | Admission timestamp |
| STOP_DATETIME | Discharge timestamp |
| ENCOUNTER_CLASS | inpatient/outpatient/ambulatory |
| TOTAL_CLAIM_COST | Total cost of encounter |
| REASON_CODE | ICD-10 diagnosis code |

### Conditions
| Column | Description |
|--------|-------------|
| PATIENT_ID | Patient reference |
| ENCOUNTER_ID | Encounter reference |
| CODE | ICD-10 code |
| DESCRIPTION | Condition description |
| START_DATE | Onset date |
| STOP_DATE | Resolution date (NULL if chronic) |

---

## Features Created

### Patient Demographics (10 features)
- Age, Gender, Marital Status
- Income level, Coverage ratio
- Geographic location

### Patient Encounter History (12 features)
- Total encounters, inpatient visits
- Cost totals and averages
- Length of stay metrics
- Unique providers/organizations

### Patient Conditions (15 features)
- Diagnosis counts by category
- Chronic condition count
- Comorbidity score
- High-risk condition flags (HF, DM, COPD, CKD, Cancer)

### Encounter Features (10 features)
- Length of stay
- Admission timing (day, hour, weekend)
- Primary diagnosis category
- Cost metrics

---

## Snowflake Features Demonstrated

| Feature | Description |
|---------|-------------|
| **Git Integration** | Sync notebooks and SQL from GitHub |
| **Internal Stages** | Secure data storage and loading |
| **Streams** | Change Data Capture for incremental processing |
| **Dynamic Tables** | Declarative data transformation pipelines |
| **Feature Store** | ML feature management with point-in-time joins |
| **Feature Views** | Versioned, refreshable feature definitions |
| **Model Registry** | Model versioning, metrics, and deployment |
| **Tasks** | Scheduled pipeline orchestration |
| **Alerts** | Automated monitoring notifications |

---

## File Structure

```
hcls-mlops-demo/
├── 00a_bootstrap.sql                         # Run FIRST - creates DB & Git repo
├── 00b_setup.sql                             # Run SECOND - creates all objects
├── README.md                                 # This file
├── data/
│   ├── patients.csv                          # Synthetic patient data (50 rows)
│   ├── encounters.csv                        # Hospital encounters (100 rows)
│   └── conditions.csv                        # Patient diagnoses (133 rows)
└── notebooks/
    ├── 01_data_ingestion_pipeline.ipynb      # Data loading & pipelines
    ├── 02_feature_engineering.ipynb          # Feature Store setup
    ├── 03_model_training.ipynb               # Model development
    └── 04_inference_monitoring.ipynb         # Production deployment
```

---

## Estimated Demo Duration

| Section | Time |
|---------|------|
| Bootstrap & Git Integration | 10 min |
| Main Setup & Data Upload | 15 min |
| Notebook 1: Data Pipeline | 25 min |
| Notebook 2: Feature Store | 25 min |
| Notebook 3: Model Training | 25 min |
| Notebook 4: Inference | 25 min |
| **Total** | **~2 hours** |

---

## Notes

- Data is synthetic (Synthea-style) and HIPAA-safe
- The same architecture works with external S3/Azure/GCS stages
- For production, add proper error handling and retry logic

---

## Resources

- [Snowflake Feature Store Documentation](https://docs.snowflake.com/en/developer-guide/snowpark-ml/feature-store)
- [Snowflake ML Model Registry](https://docs.snowflake.com/en/developer-guide/snowpark-ml/model-registry)
- [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables)
- [Git Integration](https://docs.snowflake.com/en/developer-guide/git/git-overview)
- [Streams and Tasks](https://docs.snowflake.com/en/user-guide/streams)
