-- ============================================================================
-- Healthcare MLOps Demo - Main Setup
-- ============================================================================
-- 
-- PREREQUISITE: Run 00a_bootstrap.sql first to create database and Git repo.
--
-- This script creates all remaining objects for the demo:
--   - Additional schemas
--   - Warehouse
--   - Internal stage for data files
--   - Raw tables and streams
--   - Role and privileges
--
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HEALTHCARE_MLOPS;

-- ============================================================================
-- 1. CREATE SCHEMAS
-- ============================================================================

-- Schema for raw/bronze data
CREATE SCHEMA IF NOT EXISTS RAW;

-- Schema for transformed/silver data  
CREATE SCHEMA IF NOT EXISTS CURATED;

-- Schema for feature store objects
CREATE SCHEMA IF NOT EXISTS FEATURE_STORE;

-- Schema for staging data files
CREATE SCHEMA IF NOT EXISTS STAGING;

-- ML schema already created in bootstrap

-- ============================================================================
-- 2. CREATE WAREHOUSE
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS HEALTHCARE_ML_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Healthcare MLOps demo';

USE WAREHOUSE HEALTHCARE_ML_WH;

-- ============================================================================
-- 3. CREATE INTERNAL STAGE FOR DATA FILES
-- ============================================================================

USE SCHEMA STAGING;

-- Create internal stage for uploading synthetic healthcare data
CREATE STAGE IF NOT EXISTS HEALTHCARE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for synthetic healthcare CSV data files';

-- File format for CSV data
CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

-- ============================================================================
-- 4. CREATE RAW TABLES (Landing Zone)
-- ============================================================================

USE SCHEMA RAW;

-- Patients table (demographics)
CREATE TABLE IF NOT EXISTS PATIENTS (
    PATIENT_ID VARCHAR(50) PRIMARY KEY,
    BIRTH_DATE DATE,
    DEATH_DATE DATE,
    SSN VARCHAR(20),
    DRIVERS_LICENSE VARCHAR(50),
    PASSPORT VARCHAR(50),
    PREFIX VARCHAR(10),
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    SUFFIX VARCHAR(10),
    MAIDEN_NAME VARCHAR(100),
    MARITAL_STATUS VARCHAR(20),
    RACE VARCHAR(50),
    ETHNICITY VARCHAR(50),
    GENDER VARCHAR(10),
    BIRTHPLACE VARCHAR(200),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(50),
    COUNTY VARCHAR(100),
    ZIP VARCHAR(20),
    LAT FLOAT,
    LON FLOAT,
    HEALTHCARE_EXPENSES FLOAT,
    HEALTHCARE_COVERAGE FLOAT,
    INCOME FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Encounters table (hospital visits)
CREATE TABLE IF NOT EXISTS ENCOUNTERS (
    ENCOUNTER_ID VARCHAR(50) PRIMARY KEY,
    START_DATETIME TIMESTAMP_NTZ,
    STOP_DATETIME TIMESTAMP_NTZ,
    PATIENT_ID VARCHAR(50) REFERENCES PATIENTS(PATIENT_ID),
    ORGANIZATION_ID VARCHAR(50),
    PROVIDER_ID VARCHAR(50),
    PAYER_ID VARCHAR(50),
    ENCOUNTER_CLASS VARCHAR(50),
    CODE VARCHAR(50),
    DESCRIPTION VARCHAR(500),
    BASE_ENCOUNTER_COST FLOAT,
    TOTAL_CLAIM_COST FLOAT,
    PAYER_COVERAGE FLOAT,
    REASON_CODE VARCHAR(50),
    REASON_DESCRIPTION VARCHAR(500),
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Conditions table (diagnoses)
CREATE TABLE IF NOT EXISTS CONDITIONS (
    CONDITION_ID VARCHAR(50) DEFAULT UUID_STRING(),
    START_DATE DATE,
    STOP_DATE DATE,
    PATIENT_ID VARCHAR(50) REFERENCES PATIENTS(PATIENT_ID),
    ENCOUNTER_ID VARCHAR(50) REFERENCES ENCOUNTERS(ENCOUNTER_ID),
    CODE VARCHAR(50),
    DESCRIPTION VARCHAR(500),
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Readmission labels table (for training)
CREATE TABLE IF NOT EXISTS READMISSION_LABELS (
    ENCOUNTER_ID VARCHAR(50) PRIMARY KEY REFERENCES ENCOUNTERS(ENCOUNTER_ID),
    PATIENT_ID VARCHAR(50) REFERENCES PATIENTS(PATIENT_ID),
    DISCHARGED_AT TIMESTAMP_NTZ,
    READMITTED_WITHIN_30_DAYS BOOLEAN,
    DAYS_TO_READMISSION INT,
    LABEL_GENERATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- 5. CREATE STREAMS FOR CDC (Change Data Capture)
-- ============================================================================

-- Stream on patients table to capture new/changed patients
CREATE STREAM IF NOT EXISTS PATIENTS_STREAM ON TABLE PATIENTS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for new patient records';

-- Stream on encounters table to capture new encounters
CREATE STREAM IF NOT EXISTS ENCOUNTERS_STREAM ON TABLE ENCOUNTERS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for new encounter records';

-- Stream on conditions table
CREATE STREAM IF NOT EXISTS CONDITIONS_STREAM ON TABLE CONDITIONS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for new condition records';

-- ============================================================================
-- 6. CREATE NETWORK RULE FOR EXTERNAL PACKAGES (if needed)
-- ============================================================================

-- Network rule for PyPI access (for custom packages in notebooks)
CREATE NETWORK RULE IF NOT EXISTS PYPI_NETWORK_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('pypi.org', 'files.pythonhosted.org');

CREATE EXTERNAL ACCESS INTEGRATION IF NOT EXISTS PYPI_ACCESS_INTEGRATION
    ALLOWED_NETWORK_RULES = (PYPI_NETWORK_RULE)
    ENABLED = TRUE;

-- ============================================================================
-- 7. GRANT PRIVILEGES
-- ============================================================================

-- Create role for demo users
CREATE ROLE IF NOT EXISTS HEALTHCARE_ML_ROLE;

-- Grant database privileges
GRANT USAGE ON DATABASE HEALTHCARE_MLOPS TO ROLE HEALTHCARE_ML_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE HEALTHCARE_MLOPS TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA HEALTHCARE_MLOPS.RAW TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA HEALTHCARE_MLOPS.CURATED TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA HEALTHCARE_MLOPS.FEATURE_STORE TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA HEALTHCARE_MLOPS.ML TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA HEALTHCARE_MLOPS.STAGING TO ROLE HEALTHCARE_ML_ROLE;

-- Grant table privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA HEALTHCARE_MLOPS.RAW TO ROLE HEALTHCARE_ML_ROLE;
GRANT ALL PRIVILEGES ON ALL STREAMS IN SCHEMA HEALTHCARE_MLOPS.RAW TO ROLE HEALTHCARE_ML_ROLE;

-- Grant warehouse privileges
GRANT USAGE ON WAREHOUSE HEALTHCARE_ML_WH TO ROLE HEALTHCARE_ML_ROLE;

-- Grant stage privileges
GRANT READ, WRITE ON STAGE HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE TO ROLE HEALTHCARE_ML_ROLE;

-- Grant role to current user (uncomment and adjust as needed)
-- GRANT ROLE HEALTHCARE_ML_ROLE TO USER <your_username>;

-- ============================================================================
-- 8. VERIFICATION
-- ============================================================================

-- Verify setup
SHOW SCHEMAS IN DATABASE HEALTHCARE_MLOPS;
SHOW TABLES IN SCHEMA HEALTHCARE_MLOPS.RAW;
SHOW STREAMS IN SCHEMA HEALTHCARE_MLOPS.RAW;
SHOW STAGES IN SCHEMA HEALTHCARE_MLOPS.STAGING;

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 
-- 1. Upload data files to internal stage (from local machine):
--
--    PUT file:///path/to/data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/;
--    PUT file:///path/to/data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/;
--    PUT file:///path/to/data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/;
--
--    Or using Snowflake CLI:
--    snow stage copy data/patients.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/patients/
--    snow stage copy data/encounters.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/encounters/
--    snow stage copy data/conditions.csv @HEALTHCARE_MLOPS.STAGING.HEALTHCARE_DATA_STAGE/conditions/
--
-- 2. Run the notebooks in order:
--    - 01_data_ingestion_pipeline.ipynb
--    - 02_feature_engineering.ipynb
--    - 03_model_training.ipynb
--    - 04_inference_monitoring.ipynb
--
-- ============================================================================
