-- WHAT THIS FILE DOES:
-- This is an AGGREGATED fact table — instead of one row per trip,
-- we have ONE ROW PER DAY with totals and averages.
-- This is what you'd use to make a revenue chart in a dashboard.
-- Example question it answers: "How much money did taxis make on Jan 15 2023?"

with trips as (

    -- Again reference the staging model (cleaned data)
    select * from {{ ref('stg_taxi_trips') }}

)

select
    -- DATE() = extract just the date part, drop the time
    -- Example: 2023-01-15 08:32:00 → 2023-01-15
    DATE(pickup_datetime)           as trip_date,

    -- COUNT(*) = how many trips happened on this day
    COUNT(*)                        as total_trips,

    -- SUM() = add up all fares for this day
    -- Example: 50,000 trips × avg $18 = $900,000 revenue in one day
    SUM(total_amount)               as total_revenue,

    -- AVG() = average fare per trip on this day
    AVG(total_amount)               as avg_fare,

    -- Average distance per trip on this day
    AVG(trip_distance_miles)        as avg_distance_miles,

    -- Total passengers across all trips on this day
    SUM(passenger_count)            as total_passengers

from trips

-- GROUP BY = collapse all rows with the same date into one row
-- Without this, SUM/COUNT/AVG don't know what to group together
-- Think of it like: "give me one total row FOR EACH date"
group by DATE(pickup_datetime)

-- Sort results by date oldest → newest
order by trip_date