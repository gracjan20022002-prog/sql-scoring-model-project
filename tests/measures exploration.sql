/*
====================================================================================================
📈 Data Warehouse: Analytics & Reporting Layer 
This repository contains the SQL scripts designed for the Analytics layer.
It acts as a comprehensive reporting tool to derive insights regarding corporate performance 
and market volatility based on the Gold Layer data.
====================================================================================================
The analytical logic covers the following key Business Intelligence dimensions:

1.  Financial Performance & Profitability (gold.fact_results):
    -   KPI Aggregation: Calculation of Total Revenue, Net Income, and derived Cost Structures.
    -   Margin Analysis: Computing Net Profit Margin and EBITDA Margin percentages.
    -   Growth Trends: Quarter-over-Quarter (QoQ) growth analysis using Window Functions (LAG).
    -   Seasonality: Identifying best and worst performing fiscal periods.

2.  Stock Market Dynamics & Risk Assessment (gold.fact_stockprice):
    -   Volatility Index: Measuring intra-quarter price fluctuations (High-Low Spread).
    -   Risk Metrics: Calculation of Maximum Drawdown (%) from peak to trough.
    -   Price Trends: Tracking price changes between Open and Close sessions.
    -   Ranking System: Identifying the most volatile periods per asset.

3.  Integrated Business Logic (Correlation):
    -   Fundamental Divergence: Joining financial reports with stock market data to observe 
        market reaction to earnings calls.

====================================================================================================
*/

-- ====================================================================
-- MODULE 1: FINANCIAL PERFORMANCE ANALYSIS
-- ====================================================================

-- 1. Seasonality Check (Revenue Distribution)
SELECT 
    company_id,
    fiscal_period,
    revenue_pln_mln
FROM gold.fact_results
ORDER BY company_id, revenue_pln_mln DESC;

-- 2. Total Aggregates (Revenue, Net Income, Costs)
SELECT
    company_id,
    SUM(revenue_pln_mln) AS total_revenue,
    SUM(net_income_pln_mln) AS total_net_income,
    SUM(revenue_pln_mln) - SUM(net_income_pln_mln) AS total_costs,
    SUM(ebitda_pln_mln) - SUM(net_income_pln_mln) AS total_costs_of_itda,
    SUM(revenue_pln_mln) - SUM(ebitda_pln_mln) AS total_cost_excl_itda
FROM gold.fact_results
GROUP BY company_id;

-- 3. Detailed Cost Structure (Reverse Engineering: Taxes, Depr, Amortization)
SELECT
    fr.company_id,
    dc.company_name,
    SUM(fr.ebitda_pln_mln) AS total_ebitda,
    SUM(fr.net_income_pln_mln) AS total_net_income,
    SUM(fr.ebitda_pln_mln) - SUM(fr.net_income_pln_mln) AS total_costs_of_itda,
    SUM(fr.ebit_pln_mln) AS total_ebit,
    SUM(fr.net_income_pln_mln) AS total_net_income,
    SUM(fr.ebit_pln_mln) - SUM(fr.net_income_pln_mln) AS total_costs_of_iandt,
    SUM(fr.ebitda_pln_mln) - SUM(fr.ebit_pln_mln) AS tc_of_dep_and_am
FROM gold.fact_results AS fr
LEFT JOIN gold.dim_company AS dc
    ON fr.company_id = dc.company_id
GROUP BY fr.company_id, dc.company_name
ORDER BY fr.company_id;

-- 4. Average Key Metrics
SELECT
    company_id,
    ROUND(AVG(revenue_pln_mln), 2) AS avg_revenue,
    ROUND(AVG(net_income_pln_mln), 2) AS avg_net_income,
    ROUND(AVG(ebitda_pln_mln), 2) AS avg_ebitda,
    ROUND(AVG(ebit_pln_mln), 2) AS avg_ebit
FROM gold.fact_results
GROUP BY company_id;

-- 5. Best and Worst Quarters (Revenue)
WITH order_of_results AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY MAX(revenue_pln_mln) DESC) AS nr_of_result,
        company_id,
        fiscal_period,
        MAX(revenue_pln_mln) AS revenue
    FROM gold.fact_results
    GROUP BY company_id, fiscal_period
)
SELECT 
    ofr.company_id,
    dc.company_name,
    ofr.fiscal_period,
    ofr.revenue
FROM order_of_results AS ofr
LEFT JOIN gold.dim_company AS dc
    ON ofr.company_id = dc.company_id
WHERE nr_of_result = 1 OR nr_of_result = 15
ORDER BY company_id, revenue DESC;

-- 6. Best and Worst Quarters (Net Income)
WITH order_of_netinc AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY MAX(net_income_pln_mln) DESC) AS nr_of_result,
        company_id,
        fiscal_period,
        MAX(net_income_pln_mln) AS net_income
    FROM gold.fact_results
    GROUP BY company_id, fiscal_period
)
SELECT 
    ofn.company_id,
    dc.company_name,
    ofn.fiscal_period,
    ofn.net_income
FROM order_of_netinc AS ofn
LEFT JOIN gold.dim_company AS dc
    ON ofn.company_id = dc.company_id
WHERE nr_of_result = 1 OR nr_of_result = 15
ORDER BY company_id, net_income DESC;

-- 7. Profitability Margins (Net Profit & EBITDA)
SELECT 
    fr.company_id,
    dc.company_name,
    fr.fiscal_period,
    fr.net_income_pln_mln,
    fr.revenue_pln_mln,
    CONCAT(CAST((net_income_pln_mln/NULLIF(revenue_pln_mln, 0)) * 100 AS DECIMAL(10,2)), '%') AS net_profit_margin
FROM gold.fact_results AS fr
LEFT JOIN gold.dim_company AS dc
    ON fr.company_id = dc.company_id;

SELECT 
    company_id,
    fiscal_period,
    ebitda_pln_mln,
    revenue_pln_mln,
    CONCAT(CAST((ebitda_pln_mln/NULLIF(revenue_pln_mln, 0)) * 100 AS DECIMAL(10,2)), '%') AS ebitda_margin
FROM gold.fact_results;

-- 8. Growth Analysis: Revenue QoQ
WITH rev_comp AS (
    SELECT 
        company_id,
        fiscal_period,
        revenue_pln_mln AS current_revenue,
        LAG(revenue_pln_mln) OVER (PARTITION BY company_id ORDER BY fiscal_period) AS last_q_revenue,
        revenue_pln_mln - LAG(revenue_pln_mln) OVER (PARTITION BY company_id ORDER BY fiscal_period) AS revenue_change
    FROM gold.fact_results
)
SELECT 
    company_id,
    fiscal_period,
    current_revenue,
    CASE WHEN last_q_revenue IS NULL THEN 'n/a' ELSE CAST(last_q_revenue AS NVARCHAR(50)) END AS last_q_revenue,
    CASE WHEN revenue_change IS NULL THEN 'n/a' ELSE CAST(revenue_change AS NVARCHAR(50)) END AS rev_change,
    CONCAT(CAST((current_revenue - last_q_revenue)/last_q_revenue *100 AS DECIMAL(10,2)), '%') AS perc_change
FROM rev_comp;

-- 9. Growth Analysis: Net Income QoQ
WITH netinc_comp AS (
    SELECT 
        company_id,
        fiscal_period,
        net_income_pln_mln AS current_net_income,
        LAG(net_income_pln_mln) OVER (PARTITION BY company_id ORDER BY fiscal_period) AS last_q_netinc,
        net_income_pln_mln - LAG(net_income_pln_mln) OVER (PARTITION BY company_id ORDER BY fiscal_period) AS net_inc_change
    FROM gold.fact_results
)
SELECT 
    company_id,
    fiscal_period,
    current_net_income,
    CASE WHEN last_q_netinc IS NULL THEN 'n/a' ELSE CAST(last_q_netinc AS NVARCHAR(50)) END AS last_q_netinc,
    CASE WHEN net_inc_change IS NULL THEN 'n/a' ELSE CAST(net_inc_change AS NVARCHAR(50)) END AS net_inc_change,
    CONCAT(CAST((current_net_income - last_q_netinc)/last_q_netinc *100 AS DECIMAL(10,2)), '%') AS perc_change
FROM netinc_comp;


-- ====================================================================
-- MODULE 2: STOCK MARKET DYNAMICS
-- ====================================================================

-- 10. Biggest Stock Price Change per Quarter
WITH sp_change AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY fs.company_id ORDER BY MAX(fs.stock_price_close - fs.stock_price_open) DESC) AS nr_of_result,
        dc.company_name AS company_name,
        fs.fiscal_period,
        fs.stock_price_open,
        fs.stock_price_close,
        MAX(fs.stock_price_close - fs.stock_price_open) AS max_diff
    FROM gold.fact_stockprice AS fs
    LEFT JOIN gold.dim_company AS dc
        ON fs.company_id = dc.company_id
    GROUP BY fs.company_id, dc.company_name, fs.fiscal_period, fs.stock_price_open, fs.stock_price_close
)
SELECT 
    company_name,
    fiscal_period,
    stock_price_open,
    stock_price_close,
    max_diff,
    CONCAT(CAST((max_diff/stock_price_open) * 100 AS NUMERIC(10,2)), '%') AS perc_of_change
FROM sp_change 
WHERE nr_of_result = 1 
ORDER BY max_diff/stock_price_open DESC;

-- 11. Intra-Quarter Price Change (Close vs Open)
SELECT 
    company_id,
    fiscal_period,
    stock_price_open,
    stock_price_close,
    stock_price_close - stock_price_open AS sp_change_per_q
FROM gold.fact_stockprice;

-- 12. Total Growth (First vs Last Quarter included)
WITH full_change AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY fiscal_period) AS nr_of_result,
        company_id,
        stock_price_open,
        stock_price_close
    FROM gold.fact_stockprice
)
SELECT
    company_id,
    MAX(CASE WHEN nr_of_result = 1 THEN stock_price_open END) AS start_price,
    MAX(CASE WHEN nr_of_result = 15 THEN stock_price_close END) AS end_price,
    MAX(CASE WHEN nr_of_result = 15 THEN stock_price_close END) - MAX(CASE WHEN nr_of_result = 1 THEN stock_price_open END) AS total_growth,
    CONCAT(CAST(
        ((MAX(CASE WHEN nr_of_result = 15 THEN stock_price_close END) - MAX(CASE WHEN nr_of_result = 1 THEN stock_price_open END)) 
        /
        NULLIF(MAX(CASE WHEN nr_of_result = 1 THEN stock_price_open END), 0) 
        ) * 100 
    AS NUMERIC(10, 2)), '%') AS perc_change
FROM full_change
GROUP BY company_id
ORDER BY company_id;

-- 13. Price Deviation from Average
WITH calc_price AS (
    SELECT 
        stockprice_key,
        company_id,
        fiscal_period,
        stock_price_open,
        stock_price_close,
        CAST((stock_price_open + stock_price_close)/2 AS DECIMAL(10,2)) AS avg_stock_price
    FROM gold.fact_stockprice
)
SELECT
    company_id,
    fiscal_period,
    stock_price_open,
    stock_price_close,
    avg_stock_price,
    CONCAT(CAST((stock_price_close - avg_stock_price)/NULLIF(avg_stock_price, 0) * 100 AS DECIMAL(10,2)), '%') AS deviation
FROM calc_price;

-- 14. Volatility Calculation (Min vs Max Price)
WITH fluct_calculation AS (
    SELECT 
        stockprice_key,
        company_id,
        fiscal_period,
        stock_price_min,
        stock_price_max,
        stock_price_close,
        CAST(stock_price_max - stock_price_min AS DECIMAL(10,2)) AS price_fluct
    FROM gold.fact_stockprice
)
SELECT
    dc.company_name,
    fc.fiscal_period,
    fc.stock_price_min,
    fc.stock_price_max,
    fc.stock_price_close,
    fc.price_fluct,
    CONCAT(CAST(price_fluct/NULLIF(stock_price_close, 0) * 100 AS DECIMAL(10,2)), '%') AS pr_volt
FROM fluct_calculation AS fc
LEFT JOIN gold.dim_company AS dc
    ON fc.company_id = dc.company_id
ORDER BY CAST(price_fluct/NULLIF(stock_price_close, 0) * 100 AS DECIMAL(10,2)) DESC;

-- 15. Volatility Ranking (Most Volatile Quarter per Company)
WITH fluct_calculation AS (
    SELECT 
        stockprice_key,
        company_id,
        fiscal_period,
        stock_price_min,
        stock_price_max,
        stock_price_close,
        CAST(stock_price_max - stock_price_min AS DECIMAL(10,2)) AS price_fluct
    FROM gold.fact_stockprice
),
volt_rank AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY fc.company_id ORDER BY CAST(fc.price_fluct/NULLIF(fc.stock_price_close, 0) * 100 AS DECIMAL(10,2)) DESC) AS volt_rank,
        dc.company_name,
        fc.fiscal_period,
        fc.stock_price_min,
        fc.stock_price_max,
        fc.stock_price_close,
        fc.price_fluct,
        CONCAT(CAST(price_fluct/NULLIF(stock_price_close, 0) * 100 AS DECIMAL(10,2)), '%') AS pr_volt
    FROM fluct_calculation AS fc
    LEFT JOIN gold.dim_company AS dc
        ON fc.company_id = dc.company_id
)
SELECT 
    company_name,
    fiscal_period,
    stock_price_min,
    stock_price_max,
    stock_price_close,
    price_fluct,
    pr_volt
FROM volt_rank
WHERE volt_rank = 1
ORDER BY CAST(price_fluct/NULLIF(stock_price_close, 0) * 100 AS DECIMAL(10,2)) DESC;

-- 16. Maximum Drawdown (Risk Calculation)
WITH fluct_calculation AS (
    SELECT 
        stockprice_key,
        company_id,
        fiscal_period,
        stock_price_min,
        stock_price_max,
        CAST(stock_price_min - stock_price_max AS DECIMAL(10,2)) AS price_fluct
    FROM gold.fact_stockprice
)
SELECT
    dc.company_name,
    fc.fiscal_period,
    fc.stock_price_min,
    fc.stock_price_max,
    fc.price_fluct,
    CONCAT(CAST(price_fluct/NULLIF(stock_price_max, 0) * 100 AS DECIMAL(10,2)), '%') AS pr_volt
FROM fluct_calculation AS fc
LEFT JOIN gold.dim_company AS dc
    ON fc.company_id = dc.company_id
ORDER BY CAST(price_fluct/NULLIF(stock_price_max, 0) * 100 AS DECIMAL(10,2));


-- ====================================================================
-- MODULE 3: INTEGRATED ANALYSIS (CORRELATION)
-- ====================================================================

-- 17. Correlation Check (Financial Results vs Stock Price)
SELECT
    fr.company_id,
    fr.fiscal_period,
    fr.revenue_pln_mln,
    fr.net_income_pln_mln,
    fs.stock_price_open,
    fs.stock_price_close
FROM gold.fact_results AS fr
LEFT JOIN gold.fact_stockprice AS fs
    ON fr.company_id = fs.company_id AND fr.fiscal_period = fs.fiscal_period;
