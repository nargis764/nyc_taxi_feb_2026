# NYC Yellow Taxi Analytics (February 2026)

## 📌 Project Overview
This project provides an end-to-end exploratory and advanced data analysis of the **New York City Yellow Taxi dataset** for the month of February 2026. Utilizing **PostgreSQL**, this analysis extracts critical business insights regarding revenue optimization, spatial demand distribution, high-value customer behavior, and operational trends. 

The goal of this repository is to demonstrate advanced SQL competency by leveraging **Window Functions, Common Table Expressions (CTEs), Staging Layers (Temporary Tables), and Data Aggregations** to solve complex analytics questions.

---

## 🛠️ Tech Stack & Architecture
* **Language:** SQL (PostgreSQL Dialect)
* **Interface:** pgAdmin 4
* **Database Management:** Custom Schemas (`ny_taxi`), Explicit Type Casting, Session Isolation
* **Concepts Demonstrated:** * Advanced Window Functions (`RANK()`, `PERCENT_RANK()`, `NTILE()`, `LAG()`)
  * Multi-layered Common Table Expressions (CTEs)
  * Data Transformation & Moving Averages (`ROWS BETWEEN`)
  * Staging Performance Management via Temporary Tables

---

## 📈 Key Insights & Business Findings

### 1. High-Level Performance Metrics
* **Total Trip Volume:** 3,399,866 trips completed.
* **Gross Revenue:** $102,381,021.74 generated in February 2026.
* **Average Trip Efficiency:** 6.24 miles per single trip.

### 2. Spatial Revenue Concentrations (Borough Analysis)
Manhattan remains the primary economic engine of transit, capturing the overwhelming majority of market share. However, analyzing the *revenue per trip* reveals distinct consumer patterns:
* **Manhattan** leads in absolute volume and total gross revenue.
* **Airports / Out-of-Borough** trips generate substantially higher individual ticket averages (`revenue_per_trip`), identifying them as premium operational zones.

### 3. High-Value Elite Trips (Top 5% Threshold)
By isolating the top 5% of trips using `PERCENT_RANK()`, data reveals:
* **Airport Affinity:** While airport-related trips represent a minor percentage of overall citywide volume, they account for a disproportionately massive chunk of the **Top 5% Highest-Value Trips**.
* **Financial Profile:** Top-tier trips are characterized by high average distances, premium fare baselines, and significantly higher tip percentages compared to local residential transit.

---

## 🗂️ SQL Query Catalog & Implementation

### Phase 1: Basic Analysis & Aggregations
The foundational queries focus on core business indicators: total metrics, average volumes, and basic frequency tracking.

* **Top 10 Pickup Zones by Volume:** Upper East Side South, Upper East Side North, Midtown Center, and JFK Airport lead the city in density.
* **Tipping Behavior by Payment Type:** Analyzed tip percentages dynamically utilizing zero-denominator prevention (`NULLIF`):
```sql
SELECT payment_method, 100 * AVG(tip_amount/NULLIF(fare_amount, 0)) AS avg_tip_percentage
FROM (
    SELECT payment_type, tip_amount, fare_amount,
    CASE 
       WHEN payment_type = 1 THEN 'Credit Card'
       WHEN payment_type = 2 THEN 'Cash'
       ELSE 'Other'
    END AS payment_method    
    FROM ny_taxi.yellow_taxi_trips
) sub
GROUP BY payment_method;
```
### Phase 2: Advanced Window Functions & Analytics
Demonstrating advanced analytical capabilities via windowing mechanisms to build rolling transformations and growth tracking.
**A. Daily Running Revenue Total**
Tracks cumulative financial intake day-over-day across the target month.

```
WITH day_revenue AS (
    SELECT CAST(tpep_pickup_datetime AS DATE) as day_daily, SUM(total_amount) AS total_daily_revenue
    FROM ny_taxi.yellow_taxi_trips
    GROUP BY day_daily
)
SELECT day_daily, total_daily_revenue, 
       SUM(total_daily_revenue) OVER(ORDER BY day_daily) AS running_total
FROM day_revenue;
```

**B. 7-Day Rolling Revenue Moving Average**
Smooths out intra-week volatility (weekend spikes vs. weekday drops) to observe structural trends:
```
WITH day_revenue AS (
    SELECT CAST(tpep_pickup_datetime AS DATE) as day_daily, SUM(total_amount) AS total_daily_revenue
    FROM ny_taxi.yellow_taxi_trips
    GROUP BY day_daily
)
SELECT day_daily, total_daily_revenue, 
       AVG(total_daily_revenue) OVER(ORDER BY day_daily ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg
FROM day_revenue;
```

**C. Day-over-Day Revenue Growth Rate**
Utilizes LAG() to assess relative growth vectors compared directly against the preceding calendar date:

```
WITH revenue_by_date AS (
    SELECT CAST(tpep_pickup_datetime AS DATE) AS date, SUM(total_amount) AS total_revenue
    FROM ny_taxi.yellow_taxi_trips
    GROUP BY date
),
revenue_delta AS (
    SELECT date, total_revenue AS current_day_revenue, 
           LAG(total_revenue, 1) OVER(ORDER BY date) AS previous_day_revenue
    FROM revenue_by_date
)
SELECT date, current_day_revenue, previous_day_revenue,   
       ROUND(100 * ((current_day_revenue - previous_day_revenue) / NULLIF(previous_day_revenue, 0)), 2) AS pct_growth
FROM revenue_delta;
```

💾 Staging Optimization (Temporary Tables)
To ensure optimal performance for complex downstream operations, isolated optimization tables were structured via CTAS commands:

airport_trips: Built an indexed subset table grouping trips beginning or ending inside designated Airport zones to run hyper-focused transit metrics without table scans.

top_revenue_zones: Staged data specifically for the Top 20 revenue-generating zones to run route combination optimizations.

📂 Repository File Guide
/sql_scripts/01_schema_setup.sql: Complete DDL blueprint initialization.

/sql_scripts/02_exploratory_analysis.sql: Production script housing all 20 advanced query structures.

/query_outputs/: Directory containing CSV files representing structural results for cross-validation.

Analysis compiled and engineered by a Professional Data Analyst.

