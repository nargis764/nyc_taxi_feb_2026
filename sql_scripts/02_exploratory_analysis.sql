SET search_path TO ny_taxi, public;

SELECT
    MIN(tpep_pickup_datetime),
    MAX(tpep_pickup_datetime)
FROM yellow_taxi_trips;

SELECT * FROM yellow_taxi_trips LIMIT 5;
SELECT * FROM taxi_zone_lookup LIMIT 5;


-- Phase 1: Basic Analyst Queries
-- Question 1: How many trips occurred?

SELECT COUNT(*)
FROM yellow_taxi_trips;

-- Answer: A total of 3399866 trips occurred in the month of February 2026.

-- Question 2: What was total revenue?

SELECT SUM(total_amount)
FROM yellow_taxi_trips;

-- The total revenue for the month of February, 2026 is $102381021.74

-- Question 3: What was the average trip distance?
SELECT ROUND(AVG(trip_distance), 2)
FROM yellow_taxi_trips;

-- The average trip distance is 6.24 miles.

-- Question 4: Top 10 pickup zones by trip volume

WITH merged_table AS(
SELECT yellow_taxi_trips.pulocationid, taxi_zone_lookup.zone
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON yellow_taxi_trips.pulocationid = taxi_zone_lookup.locationid
)
SELECT zone, COUNT(*) AS zone_count
FROM merged_table
GROUP BY zone
ORDER BY zone_count DESC
LIMIT 10;

-- Upper East Side South, Upper East Side North, Midtown Center, JFK Airport, Midtown East, Penn Station/Madison Sq West
--Lincoln Square East, East Village, Times Sq/Theatre District, Union Sq

-- Question 5: Top 10 pickup zones by revenue (Which pickup zones generate the most revenue?)

WITH merged_table AS(
SELECT yellow_taxi_trips.total_amount, taxi_zone_lookup.zone
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON yellow_taxi_trips.pulocationid = taxi_zone_lookup.locationid
) 
SELECT SUM(total_amount) AS total_revenue, zone
FROM merged_table
GROUP BY zone
ORDER BY total_revenue DESC
LIMIT 10;

-- Question 6: Total Revenue by borough
WITH merged_table AS(
SELECT yellow_taxi_trips.total_amount, taxi_zone_lookup.borough
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON yellow_taxi_trips.pulocationid = taxi_zone_lookup.locationid
) 
SELECT SUM(total_amount) AS total_revenue, borough
FROM merged_table
GROUP BY borough
ORDER BY total_revenue DESC

 --Extra Analysis
WITH merged_table AS(
SELECT yellow_taxi_trips.total_amount, taxi_zone_lookup.borough, yellow_taxi_trips.fare_amount
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON yellow_taxi_trips.pulocationid = taxi_zone_lookup.locationid
) 
SELECT borough, SUM(total_amount) AS total_revenue, COUNT(*) AS borough_trips, ROUND(AVG(fare_amount), 2) AS average_fare, ROUND(SUM(total_amount)/COUNT(*), 2) AS revenue_per_trip
FROM merged_table
GROUP BY borough
ORDER BY total_revenue DESC;

-- Rank Borough by total revenue

WITH merged_table AS(
SELECT SUM(yellow_taxi_trips.total_amount) AS total_revenue, taxi_zone_lookup.borough
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON yellow_taxi_trips.pulocationid = taxi_zone_lookup.locationid
GROUP BY borough
) 
SELECT borough, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS rank
FROM merged_table
;

--Question 7: Average tip percentage by payment type
SELECT payment_method, 100*AVG(tip_amount/NULLIF(fare_amount, 0)) AS avg_tip_amount
FROM (SELECT payment_type, tip_amount, fare_amount,
 CASE 
   WHEN payment_type = 0 THEN 'Flex Fare trip'
   WHEN payment_type = 1 THEN 'Credit card'
   WHEN payment_type = 2 THEN 'Cash'
   WHEN payment_type = 3 THEN 'No charge'
   WHEN payment_type = 4 THEN 'Dispute'
 END AS payment_method	 
FROM yellow_taxi_trips)
GROUP BY payment_method

-- Question 8: What hour of day generates the most revenue?
SELECT EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
GROUP BY pickup_hour
ORDER BY total_revenue DESC;

-- Question 9: Which day of week has the highest demand?
SELECT to_char(tpep_pickup_datetime, 'Day') AS day_of_week, COUNT(*) AS total_trips
FROM yellow_taxi_trips
GROUP BY day_of_week
ORDER BY total_trips DESC;

SELECT to_char(tpep_pickup_datetime, 'Day') AS day_of_week, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
GROUP BY day_of_week
ORDER BY total_revenue DESC;

-- Which routes are most profitable?
WITH merged_table AS(
SELECT pick_up_zone.zone AS pickup_zone, drop_off_zone.zone AS dropoff_zone, total_amount
FROM yellow_taxi_trips
JOIN taxi_zone_lookup pick_up_zone ON yellow_taxi_trips.pulocationid = pick_up_zone.locationid
JOIN taxi_zone_lookup drop_off_zone ON yellow_taxi_trips.dolocationid = drop_off_zone.locationid
)
SELECT pickup_zone, dropoff_zone, SUM(total_amount) AS total_revenue
FROM merged_table
GROUP BY pickup_zone, dropoff_zone
ORDER BY total_revenue DESC
LIMIT 10;

-- Question 11: Rank zones by revenue
WITH merged_table AS (
SELECT taxi_zone_lookup.zone, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY zone
)
SELECT zone, total_revenue, RANK() OVER(ORDER BY total_revenue DESC) AS rank
FROM merged_table

--Question 12: Top pickup zone(by trip count) within each borough
WITH ranked_zones AS (
SELECT borough, zone, COUNT(*) AS zone_count, RANK() OVER(PARTITION BY borough ORDER BY COUNT(*) DESC) AS rank
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY borough, zone
)
SELECT borough, zone, zone_count, rank
FROM ranked_zones
WHERE rank=1;

-- Top pickup zone(by total revenue) within each borough
WITH ranked_zones AS (
SELECT borough, zone, SUM(total_amount) AS total_revenue, RANK() OVER(PARTITION BY borough ORDER BY SUM(total_amount) DESC) AS rank
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY borough, zone
)
SELECT borough, zone, total_revenue, rank
FROM ranked_zones
WHERE rank=1;

-- Top pickup zone(by average fare) within each borough
WITH ranked_zones AS (
SELECT borough, zone, AVG(fare_amount) AS average_fare, RANK() OVER(PARTITION BY borough ORDER BY AVG(fare_amount) DESC) AS rank
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY borough, zone
)
SELECT borough, zone, average_fare, rank
FROM ranked_zones
WHERE rank=1;

-- Question 13: Running daily revenue total
WITH day_revenue AS (
SELECT CAST(tpep_pickup_datetime AS DATE) as day_daily, SUM(total_amount) AS total_daily_revenue
FROM yellow_taxi_trips
WHERE tpep_pickup_datetime >= '2026-02-01'
AND tpep_pickup_datetime < '2026-03-01'
GROUP BY day_daily
)
SELECT day_daily, total_daily_revenue, SUM(total_daily_revenue) OVER(ORDER BY day_daily) AS running_total
FROM day_revenue

-- Question 14: 7-Day Rolling Revenue

WITH day_revenue AS(
SELECT CAST(tpep_pickup_datetime AS DATE) as day_daily, SUM(total_amount) AS total_daily_revenue
FROM yellow_taxi_trips
WHERE tpep_pickup_datetime >= '2026-02-01'
AND tpep_pickup_datetime < '2026-03-01'
GROUP BY day_daily
)
SELECT day_daily, total_daily_revenue, AVG(total_daily_revenue) 
OVER(ORDER BY day_daily rows BETWEEN 6 PRECEDING AND CURRENT row) AS moving_average
FROM day_revenue;

-- Question 15: Find zones whose revenue exceeds the city average
WITH zone_average AS (
SELECT zone, SUM(total_amount) AS total_revenue,
AVG(SUM(total_amount)) OVER() AS overall_average
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY zone
)
SELECT zone, total_revenue, ROUND(overall_average, 2) AS average_amount
FROM zone_average
WHERE total_revenue > overall_average

-- Question 16: Create a temp table containing airport trips only
SELECT DISTINCT zone
FROM taxi_zone_lookup
WHERE zone ILIKE '%airport%';

CREATE TEMP TABLE airport_trips AS
SELECT yellow_taxi_trips.*, 
pick_up_zone.zone as pickup_zone, drop_off_zone.zone AS dropoff_zone, 
pick_up_zone.borough as pickup_borough, drop_off_zone.borough AS dropoff_borough
FROM yellow_taxi_trips
JOIN taxi_zone_lookup pick_up_zone ON yellow_taxi_trips.pulocationid = pick_up_zone.locationid
JOIN taxi_zone_lookup drop_off_zone ON yellow_taxi_trips.dolocationid = drop_off_zone.locationid
WHERE pick_up_zone.zone LIKE '%Airport%' OR drop_off_zone.zone LIKE '%Airport%'

-- Revenue By Airport
SELECT pickup_zone, SUM(total_amount) AS total_revenue 
FROM airport_trips
WHERE pickup_zone LIKE '%Airport%'
GROUP BY pickup_zone;

-- Top Airport Routes
SELECT pickup_zone, dropoff_zone, COUNT(*) AS routes
FROM airport_trips
GROUP BY pickup_zone, dropoff_zone
ORDER BY routes DESC;

-- Average airport fare
SELECT pickup_zone, AVG(fare_amount) AS average_fare_amount
FROM airport_trips
GROUP BY pickup_zone;

-- Airport tip percentage
SELECT 100* AVG(tip_amount/NULLIF(fare_amount, 0)) AS airport_tip_percentage
FROM airport_trips

-- Question 17: Create a temp table of top 20 revenue zones
CREATE TEMP TABLE top_revenue_zones AS 
WITH top_20_zones AS (
SELECT pulocationid, borough, zone, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY borough, zone, pulocationid
ORDER BY total_revenue DESC
LIMIT 20
)
SELECT t.*,
pick_up_zone.zone AS pickup_zone, 
drop_off_zone.zone AS dropoff_zone,
pick_up_zone.borough AS pickup_borough, 
drop_off_zone.borough AS dropoff_borough
FROM yellow_taxi_trips t
JOIN top_20_zones top_20 ON top_20.pulocationid = t.pulocationid
JOIN taxi_zone_lookup pick_up_zone ON t.pulocationid = pick_up_zone.locationid
JOIN taxi_zone_lookup drop_off_zone ON t.dolocationid = drop_off_zone.locationid;

-- Average Fare top 20 zone
SELECT pickup_zone, AVG(fare_amount) AS average_fare
FROM top_revenue_zones
GROUP BY pickup_zone;

-- Most common destinations from
SELECT dropoff_zone, COUNT(*) AS dropoff_zone_count
FROM top_revenue_zones
GROUP BY dropoff_zone
ORDER BY dropoff_zone_count DESC
LIMIT 10

-- Tip percentage in top revenue zones
SELECT pickup_zone, ROUND(100*AVG(tip_amount/NULLIF(fare_amount, 0)), 2) AS average_tip_percentage
FROM top_revenue_zones
GROUP BY pickup_zone

-- Question 18: For every borough: •Total revenue •	Revenue share % 
WITH revenue_by_borough AS (
SELECT borough, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
JOIN taxi_zone_lookup ON taxi_zone_lookup.locationid = yellow_taxi_trips.pulocationid
GROUP BY borough
)
SELECT borough, total_revenue, 
SUM(total_revenue) OVER() AS overall_total_revenue,
ROUND((total_revenue/SUM(total_revenue) OVER())*100, 2) AS percentage_revenue
FROM revenue_by_borough

-- Question 19: day-over-day revenue growth
WITH revenue_by_date AS (
SELECT CAST(tpep_pickup_datetime AS DATE) AS date, SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips
WHERE tpep_pickup_datetime >= '2026-02-01' AND tpep_pickup_datetime < '2026-03-01'
GROUP BY date
),
revenue_by_previous_date AS (
SELECT date, total_revenue AS current_day_revenue, LAG(total_revenue, 1) OVER(ORDER BY date) AS previous_day_revenue
FROM revenue_by_date
)
SELECT date, 
       current_day_revenue, 
       previous_day_revenue, 
	   ROUND(100*((current_day_revenue - previous_day_revenue)/NULLIF(previous_day_revenue, 0)), 2) AS percentage_growth
FROM revenue_by_previous_date

-- Question 20: Identify "high-value trips" Definition: (Top 5% by total_amount)
WITH ranked_trips AS (
    SELECT      
        total_amount, 
		fare_amount,
		tip_amount,
		trip_distance,
		payment_type,
        NTILE(20) OVER (ORDER BY total_amount) AS percentile_bucket
    FROM yellow_taxi_trips
)
SELECT 
    CASE WHEN percentile_bucket = 20 THEN 'top 5%'
	     ELSE 'other trips'	 
	END AS trip_groups,	 
    COUNT(*) AS num_trips,
    ROUND(AVG(total_amount), 2) AS average_revenue,
	ROUND(AVG(fare_amount), 2)AS average_fare,
    ROUND(AVG(tip_amount), 2)AS average_tip,
	ROUND(AVG(trip_distance), 2)AS average_distance		
	--percentage_bucket
    --ROUND(CAST(trip_percentile AS NUMERIC), 2) AS percentile
FROM ranked_trips
GROUP BY trip_groups

WHERE percentile_bucket = 20
ORDER BY total_amount DESC;

WITH ranked_trips AS (
    SELECT      
        total_amount,
		pick_up_zone.zone AS pickup_zone,
		drop_off_zone.zone AS dropoff_zone,		
        PERCENT_RANK() OVER (ORDER BY total_amount) AS percentile_rank
    FROM yellow_taxi_trips
	JOIN taxi_zone_lookup pick_up_zone ON yellow_taxi_trips.pulocationid = pick_up_zone.locationid
    JOIN taxi_zone_lookup drop_off_zone ON yellow_taxi_trips.dolocationid = drop_off_zone.locationid
)
SELECT COUNT(*) AS top_trip_counts_location, 
SUM(COUNT(*)) OVER() AS top_trip_counts_total,
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER(),2) AS percentage_trip_counts,
CASE WHEN pickup_zone LIKE '%Airport%' OR dropoff_zone LIKE '%Airport%' THEN 'Airports'
     ELSE 'Other zones'
END AS location	 
FROM ranked_trips
WHERE percentile_rank >= 0.95 
GROUP BY location

AND (pickup_zone LIKE '%Airport%' OR dropoff_zone LIKE '%Airport%')
GROUP BY pickup_zone, dropoff_zone
-- Peak pickup hours by borough.

-- Percentage of Airport trips among all trips
WITH all_zones AS (
SELECT pick_up_zone.zone AS pickup_zone, drop_off_zone.zone AS dropoff_zone
FROM yellow_taxi_trips
JOIN taxi_zone_lookup pick_up_zone ON pick_up_zone.locationid = yellow_taxi_trips.pulocationid
JOIN taxi_zone_lookup drop_off_zone ON drop_off_zone.locationid = yellow_taxi_trips.dolocationid
)
SELECT COUNT(*) AS trip_counts_locationwise,
       SUM(COUNT(*)) OVER() AS total_trip_counts,
	   ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER(),2) AS percentage_trip_counts,
 CASE WHEN pickup_zone LIKE '%Airport%' OR dropoff_zone LIKE '%Airport%' THEN 'Airports'
      ELSE 'Other zones'
 END AS locations	  
FROM all_zones
GROUP BY locations



