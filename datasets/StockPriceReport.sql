/*
====================================================================================================
📈 Data Warehouse: Reporting Object - Integrated Stock & Financial Performance View
   
Description: An advanced analytical view that merges fundamental financial data (Revenue/Net Income)
             with technical stock market data (Price/Volatility). 
             
             It serves as a tool for "Fundamental Analysis", allowing users to spot divergences 
             between a company's financial health and its market valuation.
====================================================================================================
The view implements complex logic to derive the following insights:

1.  Risk Assessment (Drawdown):
    -   Max Drawdown: Calculates the percentage loss from the quarterly High to the quarterly Low.
        This is a key metric for assessing the risk/volatility of holding the asset.

2.  Valuation Trends:
    -   Price-to-Sales Proxy: Tracks the trend of (Stock Price / Revenue). While not a strict P/S ratio 
        (due to outstanding shares variance), its trend indicates if the market is paying more or less 
        for each unit of revenue over time.

3.  Market Sentiment & Divergence (The "Alpha" Signal):
    -   Undervalued Signal: Flags periods where Revenue GREW YoY, but Stock Price FELL YoY.
    -   Overvalued Signal: Flags periods where Revenue FELL YoY, but Stock Price ROSE YoY.
    -   This logic helps analysts identify market inefficiencies.

4.  Growth Metrics:
    -   Standard QoQ and YoY percentage changes for both Stock Price and Revenue.

====================================================================================================
*/

CREATE VIEW stock_price_report AS
WITH sp_report AS
(
    SELECT 
        fs.company_id,
        dc.company_name,
        dc.ticker,
        fs.fiscal_period,
        
        -- Financial Fundamentals
        fr.revenue_pln_mln,
        fr.net_income_pln_mln,
        LAG(fr.revenue_pln_mln, 4) OVER (PARTITION BY fr.company_id ORDER BY fs.fiscal_period) AS prev_year_rev,
        
        -- Stock Market Data (OHLC)
        fs.stock_price_open,
        fs.stock_price_max,
        fs.stock_price_min,
        fs.stock_price_close,
        
        -- Volatility Calculation (High - Min)
        CAST(fs.stock_price_min - fs.stock_price_max AS DECIMAL(10,2)) AS price_drop,
        
        -- Historical Price for Comparison (Lag 1 Qtr & Lag 1 Year)
        LAG(fs.stock_price_close) OVER (PARTITION BY dc.company_id ORDER BY fs.fiscal_period) AS prev_q_price,
        LAG(fs.stock_price_close, 4) OVER (PARTITION BY dc.company_id ORDER BY fs.fiscal_period) AS prev_year_price,
        
        -- QoQ Price Change Calculation
        ((fs.stock_price_close - LAG(fs.stock_price_close) OVER (PARTITION BY dc.company_id ORDER BY fs.fiscal_period))
         / NULLIF(ABS(LAG(fs.stock_price_close) OVER (PARTITION BY dc.company_id ORDER BY fs.fiscal_period)), 0)) * 1
