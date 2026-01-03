/*
=====================================================================================================================================
🥇 Data Warehouse: Gold Layer
This repository contains the DDL (Data Definition Language) scripts for the Gold layer (Reporting Layer).
The Gold layer represents the "Business-Ready" zone, modeled in a Galaxy Schema for BI and Analytics.
=====================================================================================================================================
The transformation logic focuses on preparing data for consumption through:
- Dimensional Modeling: Structuring data into Dimensions (Descriptive) and Facts (Quantitative).
- Surrogate Key Generation: Creating unique identifiers ('result_key', 'stockprice_key') using ROW_NUMBER() logic.
- Data Integration: Joining normalized Silver tables to form comprehensive views for reporting tools.
- Granularity Control: Separating quarterly financial results from daily stock market fluctuations.

The schema comprises the following reporting views:
- gold.dim_company: A centralized dimension containing static company attributes (Sector, Industry).
- gold.fact_results: Quarterly financial performance facts linked to company dimensions.
- gold.fact_stockprice: Daily stock market facts (OHLC) linked to company dimensions.
=====================================================================================================================================
*/
-- Create Dimension: Company
-- Source: silver.companies_info
CREATE VIEW gold.dim_company AS
SELECT 
company_id,
ticker,
company_name,
sector,
industry
FROM silver.companies_info

-- Create Fact Table: Quarterly Financial Results
-- Source: silver.companies_info + silver.fin_reports
CREATE VIEW gold.fact_results AS
SELECT 
ROW_NUMBER() OVER (ORDER BY ci.company_id) AS result_key,
ci.company_id,
fr.fiscal_period,
fr.revenue_pln_mln,
fr.net_income_pln_mln,
fr.ebitda_pln_mln,
fr.ebit_pln_mln
FROM silver.companies_info AS ci
LEFT JOIN silver.fin_reports AS fr
ON ci.company_id = fr.company_id

-- Create Fact Table: Daily Stock Prices
-- Source: silver.companies_info + silver.key_metrics
CREATE VIEW gold.fact_stockprice AS
SELECT 
ROW_NUMBER() OVER (ORDER BY ci.company_id) AS stockprice_key,
ci.company_id,
km.fiscal_period,
km.stock_price_open,
km.stock_price_min,
km.stock_price_max,
km.stock_price_close
FROM silver.companies_info AS ci
LEFT JOIN silver.key_metrics AS km
ON ci.company_id = km.company_id;

/*
=====================================================================================================================================
🛡️ Gold Layer: Data Consistency & Integrity Check
This script performs a cross-fact validation audit to ensure data completeness across the reporting layer.
=====================================================================================================================================
The query utilizes an "Anti-Join" pattern (LEFT JOIN with IS NULL check) to identify data gaps:
- ETL Debugging: Helps isolate issues where financial reports were loaded successfully, but market data files might have failed or are incomplete.
=====================================================================================================================================
*/
SELECT *
FROM gold.fact_results r
LEFT JOIN gold.dim_company c
ON r.company_id = c.company_id
LEFT JOIN gold.fact_stockprice f
ON c.company_id = f.company_id
WHERE f.company_id IS NULL;
