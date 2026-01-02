/*
=====================================================================================================================================
🥈 Stored Procedure: Silver Layer 
The goal is to transform raw data into a cleansed, standardized, and business-ready format.
=====================================================================================================================================
The procedure 'silver.load_silver' performs the following advanced transformations:

1.  Data Standardization & Cleansing (companies_info):
    -   Trimming: Removes unwanted leading/trailing whitespace from company names.
    -   Dictionary Mapping: Normalizes sector and industry names (e.g., converting 'Tech' to 'Technology', 'fin' to 'Financials').
    -   Deduplication: Uses ROW_NUMBER() logic to ensure uniqueness of company records, keeping only the latest entry per company_id.

2.  Date Parsing & Derivation (fin_reports):
    -   Period Conversion: Parses text-based fiscal periods (e.g., 'I Q 2022') into standard End-of-Quarter (EOQ) dates (YYYY-MM-DD).
    -   Null Handling: Replaces NULL values in key financial metrics (Revenue) with 0 to ensure calculation integrity.

3.  Market Data Loading (key_metrics):
    -   Ingests historical stock price data (Open, Min, Max, Close) from the Bronze layer, preparing it for analytical aggregation.

4.  Operational Monitoring:
    -   Implements granular logging to track the execution duration of each table load.
    -   Uses Transactional patterns (TRUNCATE + INSERT) to ensure data consistency during re-runs.
=====================================================================================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY
	PRINT '=================================================';
	PRINT 'Loading Silver Layer';
	PRINT '=================================================';

	PRINT 'Loading SM Tables';
	PRINT '=================================================';
	PRINT '>>> Truncating / Inserting Data into: silver.companies_info';

	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.companies_info;
	INSERT INTO silver.companies_info (
	company_id,
	ticker,
	company_name,
	sector,
	industry)

	SELECT
	company_id,
	ticker,
	TRIM(company_name) AS company_name,
	CASE WHEN TRIM(LOWER(sector)) = 'tech' THEN TRIM('Technology')
		 WHEN TRIM(LOWER(sector)) = 'fin' THEN TRIM('Financials')
		 ELSE TRIM(sector)
	END sector,
	CASE WHEN TRIM(LOWER(industry)) = 's&s' THEN TRIM ('Software & Services')
		 ELSE TRIM(industry)
	END industry
	FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY company_id DESC) AS comp_nr
	FROM bronze.companies_info
	)t WHERE comp_nr = 1;
	SET @end_time = GETDATE();
		PRINT '>>> silver.companies_info Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
------------------------------------------------------------------------------------------------------------------------------------
	PRINT '>>> Truncating / Inserting Data into: silver.fin_reports';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.fin_reports;
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
	SET @end_time = GETDATE();
		PRINT '>>> silver.fin_reports Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
------------------------------------------------------------------------------------------------------------------------------------
	PRINT '>>> Truncating / Inserting Data into: silver.key_metrics';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.key_metrics;
	INSERT INTO silver.key_metrics (
	company_id,
	fiscal_period,
	stock_price_open,
	stock_price_min,
	stock_price_max,
	stock_price_close
	)
	SELECT
	company_id,
	fiscal_period, 
	stock_price_open,
	stock_price_min,
	stock_price_max,
	stock_price_close
	FROM bronze.key_metrics;
	DELETE FROM silver.key_metrics
	WHERE fiscal_period NOT IN ( 
	SELECT DISTINCT fiscal_eoq
	FROM silver.fin_reports
	WHERE fiscal_eoq IS NOT NULL
	);
	SET @end_time = GETDATE();
		PRINT '>>> silver.key_metrics Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
		PRINT 'Loading Silver Layer is Completed';
	END TRY
	BEGIN CATCH
	PRINT '================================================='
	PRINT 'ERRORS OCCURED DURING LOADING SILVER LAYER'
	PRINT 'Error Message' + ERROR_MESSAGE();
	END CATCH
END
