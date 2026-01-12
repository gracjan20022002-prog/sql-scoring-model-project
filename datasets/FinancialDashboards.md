# Corporate Financial & Stock Market Intelligence

## 📌 Project Overview
This project represents an **End-to-End Business Intelligence solution** that bridges the gap between Corporate Finance (Fundamental Analysis) and Stock Market Performance (Technical Analysis). 

Built on a **SQL Data Warehouse** (Gold Layer) and visualized in **Power BI**, it allows stakeholders to assess whether a company's stock valuation aligns with its actual financial results.

## 🛠️ Technology Stack
* **Backend:** SQL Server (Window Functions, CTEs, Views)
* **Data Modeling:** Galaxy Schema (Fact Financials, Fact Stock Price)
* **Frontend:** Power BI (DAX Measures, Interactive Dashboards)

---

## 📈 Dashboard 1: Financial Performance (Fundamental Analysis)
*Focus: Internal company health, efficiency, and growth trends.*

<img width="1275" height="715" alt="image" src="https://github.com/user-attachments/assets/cd342c17-7f0c-4c2e-b639-4c47f1e013a1" />


### Key Insights & Visuals:
**Revenue Dynamics:** Visualizes quarterly revenue streams against a **4-quarter Moving Average** to identify long-term growth trends versus seasonal fluctuations.

**Profitability Ratios:** deep dive into **Net Profit Margin** and **EBITDA Margin** to assess operational efficiency over time.

**Growth Dynamics:** A comparative view of Quarter-over-Quarter (QoQ) growth for Revenue vs. Net Income, highlighting periods of rapid expansion or contraction.

---

## 📉 Dashboard 2: Stock Market & Risk Analysis (Technical Analysis)
*Focus: Market sentiment, volatility, and shareholder risk.*

<img width="1276" height="716" alt="image" src="https://github.com/user-attachments/assets/3ff3176c-a047-40af-bea0-d80335861e27" />

### Key Insights & Visuals:
**Volatility Analysis:** Tracks the **intra-quarter volatility** (high-low spread) and compares it with the average stock price to identify periods of market uncertainty.

**Risk Assessment (Max Drawdown):** A dedicated "Company Drawdown" area chart highlights the maximum observed loss from peak to trough, serving as a critical risk metric for investors.

**Valuation Trends (P/S Ratio):** Monitors the Price-to-Sales trends to detect potential overvaluation or undervaluation signals.

**Market Sentiment Correlation:** A dual-axis analysis comparing **YoY Revenue Growth** vs. **YoY Stock Price Performance.**

---

## 🎛️ Interactivity & User Experience

Both dashboards are designed with a user-centric navigation pane located on the right/left sidebar.

**Dynamic Filtering:** The **Company Name** and **Fiscal Period** selectors allow users to slice data across all visuals instantly.

**Cross-Report Context:** Selecting a specific company (e.g., *Benefit Systems S.A.* or *XTB S.A.*) instantly recalculates complex measures like Moving Averages and Drawdowns specifically for that entity, filtering out noise from the rest of the market.

Time-Travel Analysis: Users can isolate specific fiscal years (2022-2025) to analyze performance during specific economic cycle.

---

## 🚀 How to Run
1.  **Database:** Execute the SQL scripts located in `sql_backend/` to create the necessary Views.
2.  **Power BI:** Open `reports/SM Stock Price Dashboard.pbix`.
3.  **Data Source:** Update the connection string to point to your local SQL Data Warehouse instance.

---
*Author: Gracjan*
