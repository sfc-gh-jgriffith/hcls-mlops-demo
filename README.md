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

## Prerequisites

- Snowflake account with:
  - ACCOUNTADMIN role (for initial setup)
  - Snowpark ML enabled
  - Snowflake Notebooks access
- Snowflake CLI (for data upload)

## Quick Start

### 1. Run Setup Script

Execute the setup script in Snowflake to create all required objects:

```sql
-- In Snowflake Worksheet or Snowsight
!source 00_setup.sql
```

### 2. Upload Data to Internal Stage

```bash
# Using Snowflake CLI
snow stage copy data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/
snow stage copy data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/
snow stage copy data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/
```

Or using SQL:
```sql
PUT file:///path/to/data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/;
PUT file:///path/to/data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/;
PUT file:///path/to/data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/;
```

### 3. Run Notebooks in Order

Import and run each notebook in Snowflake Notebooks:

1. `notebooks/01_data_ingestion_pipeline.ipynb`
2. `notebooks/02_feature_engineering.ipynb`
3. `notebooks/03_model_training.ipynb`
4. `notebooks/04_inference_monitoring.ipynb`

## Git Integration (Snowsight)

To demonstrate Snowflake's Git integration:

1. Push this repo to GitHub
2. Create Git Repository in Snowflake:

```sql
CREATE OR REPLACE GIT REPOSITORY HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO
    API_INTEGRATION = GITHUB_INTEGRATION
    ORIGIN = 'https://github.com/<your-org>/feature-store-demo.git';

-- List files from repo
LIST @HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO/branches/main/notebooks/;

-- Fetch updates
ALTER GIT REPOSITORY HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO FETCH;
```

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

## Snowflake Features Demonstrated

| Feature | Description |
|---------|-------------|
| **Internal Stages** | Secure data storage and loading |
| **Streams** | Change Data Capture for incremental processing |
| **Dynamic Tables** | Declarative data transformation pipelines |
| **Feature Store** | ML feature management with point-in-time joins |
| **Feature Views** | Versioned, refreshable feature definitions |
| **Model Registry** | Model versioning, metrics, and deployment |
| **Tasks** | Scheduled pipeline orchestration |
| **Alerts** | Automated monitoring notifications |
| **Git Integration** | Version control for notebooks and code |

## File Structure

```
feature-store-demo/
├── 00_setup.sql                              # Environment setup script
├── README.md                                 # This file
├── data/
│   ├── patients.csv                          # Synthetic patient data
│   ├── encounters.csv                        # Hospital encounters
│   └── conditions.csv                        # Patient diagnoses
└── notebooks/
    ├── 01_data_ingestion_pipeline.ipynb      # Data loading & pipelines
    ├── 02_feature_engineering.ipynb          # Feature Store setup
    ├── 03_model_training.ipynb               # Model development
    └── 04_inference_monitoring.ipynb         # Production deployment
```

## Notes

- Data is synthetic (Synthea-style) and HIPAA-safe
- The same architecture works with external S3/Azure/GCS stages
- Model monitoring requires Snowflake ML Observability (check availability)
- For production, add proper error handling and retry logic

## Estimated Demo Duration

| Section | Time |
|---------|------|
| Setup & Data Load | 10 min |
| Notebook 1: Data Pipeline | 30 min |
| Notebook 2: Feature Store | 30 min |
| Notebook 3: Model Training | 30 min |
| Notebook 4: Inference | 30 min |
| **Total** | **~2 hours** |

## Resources

- [Snowflake Feature Store Documentation](https://docs.snowflake.com/en/developer-guide/snowpark-ml/feature-store)
- [Snowflake ML Model Registry](https://docs.snowflake.com/en/developer-guide/snowpark-ml/model-registry)
- [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables)
- [Streams and Tasks](https://docs.snowflake.com/en/user-guide/streams)
