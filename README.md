# NYC Yellow Taxi Analytics (February 2026)

📌 Project Overview

This project presents an end-to-end analysis of the New York City Yellow Taxi dataset for February 2026 using PostgreSQL. The analysis focuses on identifying key revenue drivers, understanding geographic and temporal demand patterns, investigating high-value trips, and uncovering customer payment behaviors.

Through a combination of exploratory data analysis (EDA) and advanced SQL techniques, the project transforms raw trip records into actionable business insights. Key findings include the impact of airport-related travel on revenue generation, the characteristics of high-value trips, and the effect of external events such as severe weather on taxi demand.

The primary objective of this project is to demonstrate practical SQL skills commonly used in analytics roles, including data cleaning, aggregation, segmentation, trend analysis, and business-oriented reporting.

**SQL Concepts Demonstrated:**
- Aggregations and Grouping
- Multi-table Joins
- Common Table Expressions (CTEs)
- Temporary Tables for intermediate analysis
- Window Functions (`RANK()`, `PERCENT_RANK()`, `NTILE()`, `LAG()`)
- Running Totals and Trend Analysis
- 7-Day Rolling Revenue Analysis using Window Frames (`ROWS BETWEEN`)
- Revenue Segmentation and Customer Behavior Analysis
- Data Quality Investigation and Validation


## 📈 Key Insights & Business Findings

### 1. High-Level Performance Metrics
* **Total Trip Volume**: 3.4 million taxi trips were completed during February 2026.
* **Total Revenue**: Taxi operations generated over $102.4 million in revenue.
* **Average Trip Distance**: The average trip covered 6.24 miles.
* **Busiest Pickup Zones**: Upper East Side South, Upper East Side North, Midtown Center, and JFK Airport each recorded more than 100,000 pickups, making them the most active pickup locations in the city.

### 2. Revenue Distribution Across NYC
Analysis of revenue by borough highlights the concentration of taxi activity within Manhattan.

Manhattan generated the highest trip volume and total revenue, reinforcing its role as the city's primary transportation hub.
While **airport-related** and **out-of-borough** trips accounted for a smaller share of total trips, they generated substantially higher revenue per trip, making them some of the most valuable routes in the dataset.

### 3. Characteristics of High-Value Trips
Using PERCENT_RANK(), the top 5% highest-value trips were identified and analyzed.

Airport-related trips represented only a small portion of overall trip volume but accounted for a disproportionately large share of the highest-value trips.
High-value trips were generally associated with longer travel distances, higher fare amounts, and larger tip contributions compared to typical city trips.
Airport trips accounted for only **7.3% of all trips**, yet represented **77.6% of trips within the top 5% revenue segment**, highlighting their importance as a key revenue driver.

### 4. Payment Behavior and Tipping Patterns:
Analysis of payment methods revealed notable differences in tipping behavior. 

* Credit card transactions recorded an average tip rate of 25.3% of the fare amount.
* Cash transactions showed almost no recorded tips in the dataset.
* This difference is likely influenced by the way tips are captured in NYC TLC records, where credit card tips are recorded electronically while cash tips may not always be reflected in the trip data.

### 5. Operational and Temporal Insights:
Day-over-day revenue analysis identified a significant drop in trips and revenue on February 23, 2026.
Further investigation showed that the decline was consistent across vendors and hours of the day, suggesting an external event rather than a data-quality issue.
External research confirmed that a severe winter storm affected New York City on that date, providing a likely explanation for the temporary reduction in taxi demand.
Analysis of hourly demand patterns showed that peak revenue hours did not always align with peak trip-volume hours, indicating that trip profitability varies throughout the day.

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



