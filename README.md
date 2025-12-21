# SQL Scoring Model & Financial Market Analysis

Creating a scoring model that indicates changes in individual companies over a specific period. 
This project will focus on presenting the most important changes in the financial indicators of individual companies listed on the Polish Stock Exchange. 
I will focus on both creating a data warehouse as well as on in-depth analysis to create actionable insights.

---

## 📝 Project Requirements

### 1. Building the Data Warehouse (Data Engineering)

#### Objective
Develop a relational database schema using SQL to consolidate financial data from disparate sources, ensuring data integrity for analytical reporting.

#### Specifications
* **Data Sources**: 
    * Quarterly Financial Reports (Revenue, Net Income, EBIT, EPS) from listed companies (e.g., XTB, Synektik, LPP).
    * Market Data (Stock Price, P/E Ratio, Market Cap).
* **Data Modeling**: 
    * Design a Star Schema or Normalized Relational Model connecting `Companies` (Dimension) with `Financials` and `Market_Metrics` (Facts).
* **Data Quality**: 
    * Handle missing values in historical reports.
    * Standardize currency and units (PLN millions).
* **Documentation**: 
    * Maintain a clear Entity Relationship Diagram (ERD) to support business logic understanding.

### 2. BI: Analytics & Reporting (Data Analytics)

#### Objective
Develop SQL-based analytics and views to deliver detailed insights into company performance and valuation.

#### Key Analysis Areas
* **profitability Analysis**: 
    * Calculating Net Profit Margin and Operating Margin trends over the last 6-8 quarters.
* **Growth Metrics**: 
    * Year-over-Year (YoY) and Quarter-over-Quarter (QoQ) revenue and income growth.
* **Valuation Scoring**: 
    * Building a custom scoring model based on P/E ratio and earnings growth to identify undervalued companies.
* **Dividend & Efficiency**: 
    * Analyzing EPS trends and operational efficiency per sector.

---

## 🛠️ Tech Stack
* **Database**: SQL (Dialect agnostic / SQL Server / PostgreSQL)
* **Visualization**: Power BI (Planned)
* **Modeling**: Draw.io (ERD)
* **Version Control**: Git & GitHub

## 📂 Repository Structure
* `/scripts` - DDL for table creation and DML for data transformation.
* `/datasets` - Source datasets (CSV).
* `/docs` - Project documentation and diagrams.

---

## 🙋 About Me

Hi, I'm Gracjan, I'm a student specializing in accounting and financial management with ACCA, I'm trying to develop my data analysis skills and understand the stock exchange.
