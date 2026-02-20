-- ============================================================================
-- Healthcare MLOps Demo - Bootstrap Script
-- ============================================================================
-- 
-- RUN THIS FIRST in a Snowsight Worksheet before setting up the demo.
-- This creates the minimal infrastructure needed to connect the Git repository.
--
-- After running this script:
--   1. Navigate to the Git Repository in Snowsight UI
--   2. Browse the files and show the Git integration
--   3. Create notebooks from Git or set up workspace
--   4. Run 00b_setup.sql to create remaining objects
--
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. CREATE DATABASE AND ML SCHEMA
-- ============================================================================

CREATE DATABASE IF NOT EXISTS HEALTHCARE_MLOPS;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_MLOPS.ML;

-- ============================================================================
-- 2. GITHUB API INTEGRATION
-- ============================================================================
-- 
-- Check if integration already exists in your account:
-- SHOW API INTEGRATIONS LIKE 'GITHUB%';
--
-- If not, create it (requires ACCOUNTADMIN):

CREATE API INTEGRATION IF NOT EXISTS GITHUB_INTEGRATION
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/')
    ENABLED = TRUE
    COMMENT = 'Git integration for GitHub repositories';

-- ============================================================================
-- 3. CONNECT GIT REPOSITORY
-- ============================================================================

CREATE OR REPLACE GIT REPOSITORY HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO
    API_INTEGRATION = GITHUB_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-jgriffith/hcls-mlops-demo.git';

-- ============================================================================
-- 4. VERIFY CONNECTION
-- ============================================================================

-- List files from the repository
LIST @HEALTHCARE_MLOPS.ML.NOTEBOOKS_REPO/branches/main/;

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
--
-- 1. In Snowsight, navigate to:
--    Data → Databases → HEALTHCARE_MLOPS → ML → Git Repositories → NOTEBOOKS_REPO
--
-- 2. Browse the repository files in the UI
--
-- 3. Open 00b_setup.sql and run it to create all remaining objects
--
-- 4. Run the demo notebooks in order (01 → 02 → 03 → 04)
--
-- ============================================================================
