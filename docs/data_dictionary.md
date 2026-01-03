
📖 Data Dictionary: Gold Layer
This document describes the schema for the Gold Layer of the Data Warehouse, designed for BI reporting and analytics.
It consists of fact tables and dimension tables which contain specific business metrics.

### 1. Dimension Tables

#### `[gold].[dim_company]`
**Type:** Dimension 
**Description:** Stores descriptive attributes for companies. Used for filtering and grouping in reports.

| Column Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| `company_id` | `INT` | **PK** | Unique identifier for the company (Business Key). |
| `ticker` | `VARCHAR` | | Stock market ticker symbol (e.g., 'XTB'). |
| `company_name` | `VARCHAR` | | Full registered name of the company. |
| `sector` | `VARCHAR` | | Economic sector (e.g., 'Technology'). |
| `industry` | `VARCHAR` | | Specific industry classification (e.g., 'Software'). |

---

### 2. Fact Tables

#### `[gold].[fact_results]`
**Type:** Fact Table (Quarterly)
**Description:** Contains financial performance metrics derived from quarterly reports.

| Column Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| `result_key` | `BIGINT` | **PK** | Surrogate key for the fact table (generated via `ROW_NUMBER`). |
| `company_id` | `INT` | **FK** | Foreign Key linking to `dim_company`. |
| `fiscal_period` | `DATE` | | The fiscal quarter end date (e.g., '2022-03-31'). Used for time-series analysis. |
| `revenue_pln_mln` | `DECIMAL` | | Total revenue in million PLN. |
| `net_income_pln_mln` | `DECIMAL` | | Net profit/loss in million PLN. |
| `ebitda_pln_mln` | `DECIMAL` | | EBITDA value in million PLN. |
| `ebit_pln_mln` | `DECIMAL` | | EBIT (Operating Income) in million PLN. |

#### `[gold].[fact_stockprice]`
**Type:** Fact Table (Daily)
**Description:** Contains historical daily stock market quotations.

| Column Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| `stockprice_key` | `BIGINT` | **PK** | Surrogate key for the fact table (generated via `ROW_NUMBER`). |
| `company_id` | `INT` | **FK** | Foreign Key linking to `dim_company`. |
| `fiscal_period` | `DATE` | | The specific trading date (Session Date). |
| `stock_price_open` | `DECIMAL` | | Opening price of the stock. |
| `stock_price_min` | `DECIMAL` | | Minimum price recorded during the day. |
| `stock_price_max` | `DECIMAL` | | Maximum price recorded during the day. |
| `stock_price_close` | `DECIMAL` | | Closing price of the stock (final). |
