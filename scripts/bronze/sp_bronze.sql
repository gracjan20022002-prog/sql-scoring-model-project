/*
=====================================================================================================================================
🥉 Stored Procedure: Bronze Layer
The Bronze layer acts as the "Raw" zone, ingesting data directly from source systems without modification.
=====================================================================================================================================
The procedure 'bronze.load_bronze' executes the following workflow:
- Full Refresh: Truncates target tables before loading to ensure a clean slate (idempotent operation).
- Static Data Injection: Manually inserts dictionary data for company classifications (tickers, sectors).
- Bulk Ingestion: High-performance loading of CSV files ('sm_financials.csv', 'sm_metrics.csv') using BULK INSERT.
- Operational Logging: Tracks execution duration for each table to monitor performance.
- Error Handling: Encapsulates logic in TRY...CATCH blocks to manage failures and report error messages.

The procedure populates the following raw tables:
- bronze.companies_info: Static list of companies with industry classification.
- bronze.fin_reports: Raw financial data ingested from external CSV files.
- bronze.key_metrics: Raw market metrics and stock prices ingested from external CSV files.
=====================================================================================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY 
		PRINT '=================================================';
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
		('SNT', ' Synektik S.A.', 'Healthcare', 'Medical Equipment'),
		('XTB', 'XTB S.A.', 'Fin', 'Capital Markets'),
		('CBF', 'Cyber_Folks S.A.', 'Tech', 'S&S'),
		('KRU', 'Kruk S.A.', ' Fin', 'Consumer Finance'),
		('LPP', 'LPP S.A.', 'Consumer Discretionary', 'Apparel & Luxury Goods'),
		('DIG', 'Digital Network S.A.', 'Communication Services', 'Advertising'),
		('ACP', 'Asseco Poland S.A.', ' Tech ', 'IT Services'),
		('VRC', 'Vercom S.A.', 'Tech', 'S&S'),
		('TXT', 'Text S.A.', 'Tech', 'S&S'),
		('BFT', ' Benefit Systems S.A.', 'Consumer Discretionary', 'Leisure Facilities');

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
		FROM 'C:\Users\gracj\OneDrive\Dokumenty\SQL Server Management Studio 22\Templates\sql_scoringmodel_project\datasets\csv-files\sm_metrics.csv'
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
