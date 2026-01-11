/*
====================================================================================================
📊 Data Warehouse: Reporting Object - Customer Financial 360 View
   
Description: A master reporting view that consolidates key financial performance metrics 
             into a single, flat structure for BI tools (Power BI)
====================================================================================================
The view implements complex window functions to derive the following insights:

1.  Revenue Dynamics & Trends:
    -   Growth Analysis: Quarter-over-Quarter (QoQ) and Year-over-Year (YoY) percentage changes.
    -   Trend Smoothing: 4-Quarter Moving Average (Rolling Annual Trend) to identify signal vs. noise.
    -   Contribution: Percentage share of specific quarter revenue against total historical revenue.
    -   Benchmarks: comparison of current results vs. the moving average ('Above/Below Avg').

2.  Profitability & Efficiency:
    -   Margins: Calculation of Net Profit Margin and EBITDA Margin.
    -   Profit Growth: Tracking Net Income changes over time.

3.  Technical Implementation:
    -   CTE (cust_cte): Pre-calculates heavy window functions (LAG, SUM OVER, AVG sliding window).
    -   Outer Query: Handles formatting (CAST/CONCAT), null handling (COALESCE), and text labels.

====================================================================================================
*/

CREATE VIEW gold.customer_report AS
WITH cust_cte AS
(
    SELECT 
        fr.company_id,
        dc.company_name,
        dc.ticker,
        fr.fiscal_period,
        
        -- Core Metrics
        fr.revenue_pln_mln,
        
        -- Revenue Lag Analysis (Previous Quarter & Previous Year)
        LAG(fr.revenue_pln_mln) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period) AS last_q_revenue,
        fr.revenue_pln_mln - LAG(fr.revenue_pln_mln) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period) AS revenue_change,
        LAG(fr.revenue_pln_mln, 4) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period) AS prev_year_rev,
        
        -- Revenue Contribution (Share of Total History)
        (CAST(fr.revenue_pln_mln AS FLOAT) / SUM(fr.revenue_pln_mln) OVER (PARTITION BY fr.company_id)) * 100 AS rv_per,
        
        -- Trend Analysis: 4-Quarter Moving Average (Rolling Window)
        CAST(AVG(fr.revenue_pln_mln) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)) AS moving_avg_rev,
        
        SUM(fr.revenue_pln_mln) OVER (PARTITION BY fr.company_id) AS total_revenue,
        
        -- Profitability Metrics
        fr.net_income_pln_mln,
        LAG(fr.net_income_pln_mln) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period) AS last_q_net_inc,
        fr.net_income_pln_mln - LAG(fr.net_income_pln_mln) OVER (PARTITION BY fr.company_id ORDER BY fiscal_period) AS net_inc_change,
        
        -- Margin Ratios
        CONCAT(CAST((fr.net_income_pln_mln/NULLIF(revenue_pln_mln, 0)) * 100 AS DECIMAL(10,2)), '%') AS net_profit_margin,
        fr.ebitda_pln_mln, 
        CONCAT(CAST((fr.ebitda_pln_mln/NULLIF(revenue_pln_mln, 0)) * 100 AS DECIMAL(10,2)), '%') AS ebitda_margin,
        fr.ebit_pln_mln
    
    FROM gold.fact_results AS fr
    LEFT JOIN gold.dim_company AS dc
        ON fr.company_id = dc.company_id
)
SELECT 
    company_id,
    company_name,
    ticker,
    fiscal_period,
    
    -- === REVENUE SECTION ===
    revenue_pln_mln,
    
    -- QoQ Analysis
    COALESCE(CAST(last_q_revenue AS NVARCHAR(50)), 'n/a') AS last_q_revenue,
    COALESCE(CAST(revenue_change AS NVARCHAR(50)), 'n/a') AS rev_change,
    CASE WHEN last_q_revenue IS NULL THEN 'n/a'
         ELSE CONCAT(CAST(((revenue_pln_mln - last_q_revenue)/ NULLIF(ABS(last_q_revenue), 0)) * 100 AS DECIMAL(10,2)), '%') 
    END AS perc_change_qoq,
    
    -- YoY Analysis
    COALESCE(CAST(prev_year_rev AS NVARCHAR(50)), 'n/a') AS prev_year_rev,
    COALESCE(CAST(revenue_pln_mln - prev_year_rev AS NVARCHAR(50)), 'n/a') AS rev_change_yoy,
    CASE WHEN prev_year_rev IS NULL THEN 'n/a'
         ELSE CONCAT(CAST(((revenue_pln_mln - prev_year_rev) / NULLIF(ABS(prev_year_rev), 0)) * 100 AS DECIMAL(10,2)), '%') 
    END AS rev_change_yoy_pct,
    
    total_revenue,
    CONCAT(ROUND(rv_per, 2), '%') AS perc_of_total_rev,
    
    -- Moving Average Comparison
    moving_avg_rev,
    CASE WHEN revenue_pln_mln < moving_avg_rev THEN 'Below Avg'
         WHEN revenue_pln_mln > moving_avg_rev THEN 'Above Avg'
         ELSE 'Average'
    END AS rev_vs_moving_avg,
    
    -- === PROFITABILITY SECTION ===
    net_income_pln_mln,
    COALESCE(CAST(last_q_net_inc AS NVARCHAR(50)), 'n/a') AS last_q_net_inc,
    COALESCE(CAST(net_inc_change AS NVARCHAR(50)), 'n/a') AS net_inc_change,
    CASE WHEN last_q_net_inc IS NULL THEN 'n/a
