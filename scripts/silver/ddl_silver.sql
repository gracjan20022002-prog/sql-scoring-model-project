/*
=====================================================================================================================================
🥈 Data Warehouse: Silver Layer
This repository contains the DDL (Data Definition Language) and DML (Data Manipulation Language) scripts for the Silver layer.
The Silver layer represents the "Cleansed" and "Standardized" zone of the Data Warehouse.
=====================================================================================================================================
The transformation logic focuses on refining raw data from the Bronze layer through:
- Type Casting: Converting legacy text formats (e.g., 'I Q 2022') into standard SQL DATE types.
- Data Quality Checks: Identifying and removing records with missing keys or invalid business logic,
- Standardization: Normalizing numeric formats and handling NULL values in financial indicators.
- Referential Integrity: Ensuring that key metrics align with reported financial periods.

The schema comprises the following optimized tables:
- silver.companies_info: Master data for companies with standardized naming conventions.
- silver.fin_reports: Financial data with parsed dates and validated numeric fields.
- silver.key_metrics: Daily market metrics cleaned of "orphan" records and non-calendar dates.
=====================================================================================================================================
*/
IF OBJECT_ID ('silver.companies_info', 'U') IS NOT NULL
    DROP TABLE silver.companies_info;
CREATE TABLE silver.companies_info (
    company_id INT PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    company_name VARCHAR(100),
    sector VARCHAR(50),
    industry VARCHAR(50)
);

IF OBJECT_ID ('silver.fin_reports', 'U') IS NOT NULL
    DROP TABLE silver.fin_reports;
CREATE TABLE silver.fin_reports (
    company_id INT,
    fiscal_period VARCHAR(10), 
    revenue_pln_mln DECIMAL(10,2),
    net_income_pln_mln DECIMAL(10,2),
    ebitda_pln_mln DECIMAL(10,2),
    ebit_pln_mln DECIMAL(10,2)
);

IF OBJECT_ID ('silver.key_metrics', 'U') IS NOT NULL
    DROP TABLE silver.key_metrics;

CREATE TABLE silver.key_metrics (
    company_id INT,
    fiscal_period DATE,
    stock_price_open DECIMAL(10,2),
    stock_price_min DECIMAL(10,2),   
    stock_price_max DECIMAL(10,2), 
    stock_price_close DECIMAL(10,2)
      
);
