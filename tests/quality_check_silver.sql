/*
=====================================================================================================================================
🥈 Data Warehouse: Silver Layer - Data Quality & Validation Script
This script performs comprehensive quality checks and data cleaning on the Silver layer.
It acts as a diagnostic tool to validate data integrity, consistency, and completeness after the ETL process.
=====================================================================================================================================
The validation logic covers the following key Data Quality dimensions:

1.  Uniqueness & String Hygiene (silver.companies_info):
    -   Duplicate Detection: Checks for violation of Primary Key constraints on 'company_id'.
    -   Whitespace Auditing: Identifies unnecessary leading/trailing spaces in text fields (Sector, Industry) that could affect grouping.

2.  Business Rules & Domain Integrity (silver.fin_reports):
    -   Range Constraints: Validates that 'company_id' falls within the expected range (1-10) and filters out invalid identifiers.
    -   Financial Logic: Flags anomalies such as negative Revenue or NULL values where strict numeric data is required.
    -   Transformation Verification: re-validates the conversion logic from text-based quarters ('I Q 2022') to Date formats.

3.  Referential Integrity & Temporal Consistency (silver.key_metrics):
    -   Orphan Removal: Identifies and deletes metric records that do not have a corresponding parent record in the financial reports table.
    -   Date Validity: Uses TRY_CAST to detect deformed date strings before enforcing strict DATE data types.
    -   Price Anomalies: Checks for impossible values (e.g., negative stock prices) and out-of-bounds dates (future dates or legacy data < 2022).

4.  Schema Refinement:
    -   Includes DDL commands (ALTER TABLE) to finalize data types (changing VARCHAR to DATE) after validation passes.
=====================================================================================================================================
*/
-- silver.companies_info
-- Checking for Nulls or Duplicates in Primary Key
SELECT 
company_id,
COUNT(*) AS nr_of_same_companies
FROM silver.companies_info
GROUP BY company_id
HAVING COUNT(*) > 1;

-- Handling Nulls and Duplicates if they exist
SELECT *
FROM (
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY company_id DESC) AS comp_nr
FROM silver.companies_info
)t WHERE comp_nr = 1;

-- Checking for useless spaces
SELECT 
company_name
FROM silver.companies_info
WHERE company_name != TRIM(company_name);

SELECT 
sector
FROM silver.companies_info
WHERE sector != TRIM(sector);

SELECT 
industry
FROM silver.companies_info
WHERE industry != TRIM(industry);

-- silver.fin_reports
-- Checking for Nulls or Duplicates in Primary Key
SELECT 
company_id,
COUNT(*) AS nr_of_same_companies
FROM silver.fin_reports
GROUP BY company_id
HAVING COUNT(*) > 1;

-- Checking for unwanted companies
SELECT
DISTINCT company_id
FROM silver.fin_reports
GROUP BY company_id
HAVING company_id IS NULL OR company_id NOT BETWEEN 1 AND 10;

-- Changing the format of the Fiscal Period
INSERT INTO silver.fin_reports (
    company_id,
    fiscal_period,
    fiscal_eoq,
    revenue_pln_mln,
    net_income_pln_mln,
    ebitda_pln_mln,
    ebit_pln_mln
    )
SELECT 
company_id,
fiscal_period,
CASE WHEN fiscal_period LIKE 'I Q%' THEN CONCAT(RIGHT(fiscal_period, 4),'-03-31')
	 WHEN fiscal_period LIKE 'II Q%' THEN CONCAT(RIGHT(fiscal_period, 4),'-06-30')
	 WHEN fiscal_period LIKE 'III Q%' THEN CONCAT(RIGHT(fiscal_period, 4),'-09-30')
	 WHEN fiscal_period LIKE 'IV Q%' THEN CONCAT(RIGHT(fiscal_period, 4),'-12-31')
END fiscal_eoq,
ISNULL(revenue_pln_mln, 0) AS revenue_pln_mln,
net_income_pln_mln,
ebitda_pln_mln,
ebit_pln_mln
FROM bronze.fin_reports; 

-- Checking for Nulls and Negative Numbers
SELECT 
revenue_pln_mln
FROM silver.fin_reports
WHERE revenue_pln_mln < 0 OR revenue_pln_mln IS NULL;

INSERT INTO silver.fin_reports (
fiscal_eoq
)
SELECT 
CAST(fiscal_eoq AS DATE) AS fiscal_eoq
FROM silver.fin_reports;

-- silver.key_metrics
-- Checking possible invalid Dates
SELECT 
fiscal_period
FROM silver.key_metrics
WHERE TRY_CAST(fiscal_period AS DATE) IS NULL
	AND fiscal_period IS NOT NULL;

-- Changing fiscal_period datatype to DATE
ALTER TABLE silver.key_metrics
ALTER COLUMN fiscal_period DATE;


-- Checking the quality of the Data
SELECT
company_id,
fiscal_period,
stock_price_open,
stock_price_min,
stock_price_max,
stock_price_close
FROM silver.key_metrics
WHERE fiscal_period NOT IN (SELECT fiscal_eoq FROM silver.fin_reports);

SELECT 
stock_price_max
FROM silver.key_metrics
WHERE stock_price_max < 0; 

-- Data standardization 
DELETE FROM silver.key_metrics
WHERE fiscal_period NOT IN ( 
	SELECT DISTINCT fiscal_eoq
	FROM silver.fin_reports
	WHERE fiscal_eoq IS NOT NULL
);

SELECT DISTINCT 
fiscal_period 
FROM silver.key_metrics
WHERE fiscal_period < '2022-03-31' OR fiscal_period > GETDATE();

SELECT * FROM silver.key_metrics;
