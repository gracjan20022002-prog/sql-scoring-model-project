/*
=====================================================================================================================================
🥉 Data Warehouse: Bronze Layer Ingestion
This repository contains the ETL (Extract, Transform, Load) logic for ingesting raw data into the Bronze layer of the Data Warehouse.
=====================================================================================================================================
The core component is the bronze.load_bronze stored procedure, which handles:
- Data Cleaning: Truncating target tables before loading new data.
- Static Data Insertion: Loading constant company information (e.g., sector, industry).
- Bulk Data Import: Efficiently loading large financial and market datasets from external CSV files using BULK INSERT.
- Process Monitoring: Tracking and logging execution time for each ingestion step.
- Error Handling: Managing exceptions with a try-catch block to ensure process stability.

The procedure populates the following tables in the bronze schema:
- bronze.companies_info: Basic company details.
-bronze.fin_reports: Raw quarterly financial reports.
-bronze.key_metrics: Historical stock prices and market metrics.
=====================================================================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY 
		PRINT 'Loading Bronze Layer';
		PRINT '=================================================';

		PRINT 'Loading SM Tables';
		PRINT '=================================================';

	-- Inserting values into tables 

		PRINT 'Truncating And Inserting Data Into Tables';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.companies_info;

		INSERT INTO bronze.companies_info (ticker, company_name, sector, industry)
		VALUES
		('SNT', 'Synektik S.A.', 'Healthcare', 'Medical Equipment'),
		('XTB', 'XTB S.A.', 'Financials', 'Capital Markets'),
		('CBF', 'Cyber_Folks S.A.', 'Technology', 'Software & Services'),
		('KRU', 'Kruk S.A.', 'Financials', 'Consumer Finance'),
		('LPP', 'LPP S.A.', 'Consumer Discretionary', 'Apparel & Luxury Goods'),
		('DIG', 'Digital Network S.A.', 'Communication Services', 'Advertising'),
		('ACP', 'Asseco Poland S.A.', 'Technology', 'IT Services'),
		('VRC', 'Vercom S.A.', 'Technology', 'Software & Services'),
		('TXT', 'Text S.A.', 'Technology', 'Software & Services'),
		('BFT', 'Benefit Systems S.A.', 'Consumer Discretionary', 'Leisure Facilities');

		SET @end_time = GETDATE();
		PRINT '>> bronze.companies_info Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
		--------------------------------------------------------------------------------

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.fin_reports;

		BULK INSERT bronze.fin_reports
		FROM 'C:\Users\gracj\OneDrive\Dokumenty\SQL Server Management Studio 22\Templates\sql_scoringmodel_project\datasets\csv-files\sm_financials.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> bronze.fin_reports Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
		--------------------------------------------------------------------------------

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.key_metrics;

		BULK INSERT bronze.key_metrics
		FROM 'C:\Users\gracj\OneDrive\Dokumenty\SQL Server Management Studio 22\Templates\sql_scoringmodel_project\datasets\csv-files\sm_metrics1.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> bronze.key_metrics Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';
		PRINT 'Loading Bronze Layer is Completed';
	END TRY
	BEGIN CATCH
	PRINT '================================================='
	PRINT 'ERRORS OCCURED DURING LOADING BRONZE LAYER'
	PRINT 'Error Message' + ERROR_MESSAGE();
	END CATCH
END
