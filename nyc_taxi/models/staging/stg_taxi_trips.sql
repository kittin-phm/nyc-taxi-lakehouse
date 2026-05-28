-- WHAT THIS FILE DOES:
-- This is the "cleaning" layer. Raw data is messy — column names are weird,
-- some rows have bad data (zero fares, null dates). We fix all of that here.
-- Think of it like: wash the vegetables before cooking.

-- "with" = CTE (Common Table Expression) = a temporary named query
-- You can think of it like: source = a variable that holds the raw table
with source as (

    -- {{ source('nyc_taxi', 'raw_trips') }} is dbt syntax
    -- It means: "go find the table called raw_trips inside the nyc_taxi dataset"
    -- dbt will replace this with the real BigQuery table path automatically
    select * from {{ source('nyc_taxi', 'raw_trips') }}

),

-- Second CTE: take the source and clean it up
cleaned as (

    select
        -- "as" = rename the column
        -- Original name VendorID is inconsistent (capital letters) 
        -- We rename to vendor_id (snake_case = standard in data engineering)
        VendorID                                    as vendor_id,

        -- Rename pickup/dropoff timestamps to cleaner names
        tpep_pickup_datetime                        as pickup_datetime,
        tpep_dropoff_datetime                       as dropoff_datetime,

        -- These names are already fine, keep them
        passenger_count                             as passenger_count,

        -- Add "_miles" to be explicit about the unit
        trip_distance                               as trip_distance_miles,

        -- PU = PickUp, DO = DropOff — rename to be readable
        PULocationID                                as pickup_location_id,
        DOLocationID                                as dropoff_location_id,

        -- These financial columns are already clean
        fare_amount,
        tip_amount,
        total_amount,

        -- DERIVED COLUMN: calculate trip duration ourselves
        -- TIMESTAMP_DIFF = BigQuery function: subtract two timestamps
        -- MINUTE = return the result in minutes
        -- Example: dropoff=10:35, pickup=10:10 → result = 25 minutes
        TIMESTAMP_DIFF(tpep_dropoff_datetime, tpep_pickup_datetime, MINUTE)
                                                    as trip_duration_minutes

    from source

    -- WHERE = filter out bad rows (like WHERE in normal SQL)
    where
        total_amount > 0              -- remove free/negative fares (data errors)
        and trip_distance > 0         -- remove trips that went nowhere
        and passenger_count > 0       -- remove empty taxi logs
        and tpep_pickup_datetime is not null   -- must have a start time
        and tpep_dropoff_datetime is not null  -- must have an end time

)

-- Final SELECT: return everything from the cleaned CTE
-- dbt will create a VIEW in BigQuery with this result
select * from cleaned