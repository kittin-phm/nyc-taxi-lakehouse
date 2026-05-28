# load_to_bq.py
# This script reads parquet files from S3 and loads them into BigQuery
# Think of it like: "copy data from AWS folder → GCP table"

import boto3                          # AWS SDK for Python
import pandas as pd                   # data manipulation library
from google.cloud import bigquery     # GCP BigQuery SDK
import io                             # lets us treat bytes like a file

# ── Config ──────────────────────────────────────────────
S3_BUCKET    = "nyc-taxi-raw-kittinphm"
BQ_PROJECT   = "nyc-taxi-lakehouse-497608"
BQ_DATASET   = "nyc_taxi"
BQ_TABLE     = "raw_trips"

# Files to load — each mapped to its S3 path
FILES = [
    "year=2023/month=01/yellow_tripdata_2023-01.parquet",
    "year=2023/month=02/yellow_tripdata_2023-02.parquet",
    "year=2023/month=03/yellow_tripdata_2023-03.parquet",
]

# ── Clients ─────────────────────────────────────────────
# boto3 = Python library to talk to AWS (like requests but for AWS)
s3 = boto3.client("s3", region_name="ap-southeast-1")

# bigquery.Client = Python library to talk to GCP BigQuery
bq = bigquery.Client(project=BQ_PROJECT)

# Full table reference: project.dataset.table
table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE}"

# ── Columns we want (must match BigQuery schema) ─────────
COLUMNS = [
    "VendorID", "tpep_pickup_datetime", "tpep_dropoff_datetime",
    "passenger_count", "trip_distance", "PULocationID",
    "DOLocationID", "fare_amount", "tip_amount", "total_amount"
]

# ── Load each file ───────────────────────────────────────
for file_path in FILES:
    print(f"\n Loading: {file_path}")

    # Step 1: Download file from S3 into memory (not saved to disk)
    # get_object = "fetch this file from S3"
    # Body.read() = read the raw bytes
    response = s3.get_object(Bucket=S3_BUCKET, Key=file_path)
    file_bytes = response["Body"].read()

    # Step 2: Read parquet bytes into a pandas DataFrame
    # DataFrame = like an Excel table in Python memory
    # io.BytesIO = treats raw bytes as a file object so pandas can read it
    df = pd.read_parquet(io.BytesIO(file_bytes), columns=COLUMNS)

    print(f"   Rows loaded: {len(df):,}")
    print(f"   Columns: {list(df.columns)}")

    # Step 3: Upload DataFrame to BigQuery
    # to_gbq = pandas function that writes directly to BigQuery
    # if_exists="append" = add rows, don't replace existing data
    df.to_gbq(
        destination_table=f"{BQ_DATASET}.{BQ_TABLE}",
        project_id=BQ_PROJECT,
        if_exists="append",
        progress_bar=True
    )

    print(f"   Uploaded to BigQuery!")

print("\n All files loaded into BigQuery successfully!")