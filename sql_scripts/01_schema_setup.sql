-- creating schema for taxi_zone_lookups
CREATE TABLE IF NOT EXISTS ny_taxi.taxi_zone_lookup(
LocationID INT PRIMARY KEY,     
Borough VARCHAR(50),
Zone VARCHAR(100),
service_zone VARCHAR(50)
);

-- creating schema for yellow_taxi_trips
CREATE TABLE IF NOT EXISTS ny_taxi.yellow_taxi_trips(
VendorID INT,                 
tpep_pickup_datetime TIMESTAMP,
tpep_dropoff_datetime TIMESTAMP,
passenger_count REAL,
trip_distance NUMERIC(10, 2),           
RatecodeID REAL,            
store_and_fwd_flag VARCHAR(5),
PULocationID INT REFERENCES ny_taxi.taxi_zone_lookup(LocationID),
DOLocationID INT REFERENCES ny_taxi.taxi_zone_lookup(LocationID),
payment_type INT,          
fare_amount NUMERIC(10, 2),  
extra NUMERIC(10, 2), 
mta_tax NUMERIC(10, 2),
tip_amount NUMERIC(10, 2),
tolls_amount NUMERIC(10, 2),
improvement_surcharge NUMERIC(10, 2),
total_amount NUMERIC(10, 2),
congestion_surcharge NUMERIC(10, 2),
Airport_fee NUMERIC(10, 2),
cbd_congestion_fee NUMERIC(10, 2),
);
