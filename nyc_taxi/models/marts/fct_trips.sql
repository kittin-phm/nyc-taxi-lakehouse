-- WHAT THIS FILE DOES:
-- This is the "business layer". Analysts query this table directly.
-- "fct" = fact table = one row per business event (here: one row per trip)
-- We add extra useful columns like day_of_week and pickup_hour
-- so analysts don't have to calculate them every time.

-- Pull from staging (the cleaned data we made in File 1)
-- {{ ref('stg_taxi_trips') }} = dbt syntax meaning "use stg_taxi_trips model"
-- dbt automatically runs stg_taxi_trips FIRST before this model
-- This is called "dependency management" — dbt figures out the order
with trips as (

    select * from {{ ref('stg_taxi_trips') }}

)

select
    -- Generate a unique ID for each trip
    -- ROW_NUMBER() = assigns 1, 2, 3, 4... to each row
    -- OVER (ORDER BY pickup_datetime) = ordered by time
    -- So trip 1 = earliest trip, trip 9384487 = latest trip
    ROW_NUMBER() OVER (ORDER BY pickup_datetime)    as trip_id,

    -- Bring through all the cleaned columns from staging
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    passenger_count,
    trip_distance_miles,
    fare_amount,
    tip_amount,
    total_amount,
    trip_duration_minutes,

    -- NEW: What day of the week was this trip?
    -- FORMAT_DATE('%A', ...) = returns "Monday", "Tuesday", etc.
    -- DATE(pickup_datetime) = extract just the date part from the timestamp
    -- Example: 2023-01-15 08:32:00 → "Sunday"
    FORMAT_DATE('%A', DATE(pickup_datetime))        as day_of_week,

    -- NEW: What hour did the trip start?
    -- EXTRACT(HOUR FROM ...) = pulls just the hour number (0-23)
    -- Example: 2023-01-15 08:32:00 → 8
    -- Useful for: "are tips higher during rush hour?"
    EXTRACT(HOUR FROM pickup_datetime)              as pickup_hour

from trips