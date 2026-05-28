# NYC Taxi Batch Lakehouse — Multi-Cloud Data Engineering

A production-style data engineering project built on **AWS + GCP free tier**, processing **9.3 million real NYC taxi trips** through a fully automated batch pipeline.

---

## Architecture

```
NYC TLC Data (Parquet)
        │
        ▼
  AWS S3 (Raw Storage)          ← Partitioned by year/month
  ap-southeast-1 (Singapore)
        │
        ▼
   Python (load_to_bq.py)       ← Reads S3, loads into BigQuery
        │
        ▼
  GCP BigQuery (raw_trips)      ← 9.3M rows, day-partitioned
  asia-southeast1 (Singapore)
        │
        ▼
     dbt (Transform)
   ┌────────────────┐
   │ stg_taxi_trips │  ← Staging: clean, rename, filter
   └────────┬───────┘
            │
   ┌────────┴────────────────┐
   │                         │
   ▼                         ▼
fct_trips              fct_revenue        ← Mart: business-ready tables
(1 row per trip)       (1 row per day)
        │
        ▼
   dbt test (8 tests)         ← not_null, unique, accepted_values
        │
        ▼
GitHub Actions CI/CD           ← Runs on every git push
```

---

## Tech Stack

| Tool | Purpose | Version |
|------|---------|---------|
| **Terraform** | Infrastructure as Code (AWS + GCP) | >= 1.0 |
| **AWS S3** | Raw data storage with hive partitioning | Free Tier |
| **GCP BigQuery** | Analytical query engine | Free Tier |
| **dbt** | SQL transformations + data quality tests | dbt-bigquery |
| **Python** | Data ingestion from S3 → BigQuery | 3.11 |
| **GitHub Actions** | CI/CD — auto runs dbt on every push | - |

---

## Project Structure

```
nyc-taxi-lakehouse/
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Terraform entry point + providers
│   ├── variables.tf            # Input variables
│   ├── aws.tf                  # S3 bucket + partitions
│   ├── gcp.tf                  # BigQuery dataset + table
│   └── outputs.tf              # Output values
│
├── nyc_taxi/                   # dbt project
│   ├── models/
│   │   ├── staging/
│   │   │   └── stg_taxi_trips.sql    # Clean + rename raw data
│   │   ├── marts/
│   │   │   ├── fct_trips.sql         # One row per trip
│   │   │   └── fct_revenue.sql       # Daily revenue aggregation
│   │   └── schema.yml                # Data quality tests
│   └── dbt_project.yml
│
├── .github/
│   └── workflows/
│       └── dbt.yml             # CI/CD pipeline
│
├── load_to_bq.py               # Load parquet from S3 → BigQuery
└── README.md
```

---

## Data Pipeline Details

### 1. Infrastructure (Terraform)
- Provisioned **AWS S3** bucket in `ap-southeast-1` with hive-style partitions:
  ```
  s3://nyc-taxi-raw-kittinphm/year=2023/month=01/
  s3://nyc-taxi-raw-kittinphm/year=2023/month=02/
  s3://nyc-taxi-raw-kittinphm/year=2023/month=03/
  ```
- Provisioned **GCP BigQuery** dataset with day-partitioned table on `tpep_pickup_datetime`
- Partitioning cuts query costs on 3–5 GB historical workloads by scanning only relevant slices

### 2. Data Ingestion
- Source: NYC TLC Yellow Taxi Trip Records (public dataset)
- Format: Apache Parquet (columnar — ~5x smaller than CSV)
- Volume: **9,384,487 rows** across Jan–Mar 2023
- Script: `load_to_bq.py` reads from S3 using `boto3`, loads to BigQuery using `pandas-gbq`

### 3. dbt Transformations

**Staging layer** (`stg_taxi_trips`) — view materialization:
- Renames columns to snake_case
- Casts data types
- Filters out bad rows (zero fares, null timestamps, empty taxis)
- Calculates `trip_duration_minutes` using `TIMESTAMP_DIFF`

**Mart layer** — table materialization:
- `fct_trips`: one row per trip, adds `day_of_week` and `pickup_hour`
- `fct_revenue`: aggregated daily revenue with `total_trips`, `avg_fare`, `avg_distance_miles`

### 4. Data Quality Tests (8 tests, all passing ✅)
Applied via `schema.yml` across all mart layers:

| Model | Column | Test |
|-------|--------|------|
| stg_taxi_trips | pickup_datetime | not_null |
| stg_taxi_trips | total_amount | not_null |
| stg_taxi_trips | vendor_id | not_null, accepted_values [1,2] |
| fct_trips | trip_id | not_null, unique |
| fct_revenue | trip_date | not_null, unique |

### 5. CI/CD (GitHub Actions)
- Triggered on every push to `main`
- Installs dbt, recreates credentials from GitHub Secrets
- Runs `dbt run` → `dbt test` automatically
- Zero-touch deployment — no manual steps needed

---

## Setup & Reproduction

### Prerequisites
- AWS account (free tier)
- GCP account (free tier)
- Python 3.11+
- Terraform >= 1.0
- dbt-bigquery

### 1. Clone the repo
```bash
git clone https://github.com/kittin-phm/nyc-taxi-lakehouse.git
cd nyc-taxi-lakehouse
```

### 2. Provision infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 3. Install Python dependencies
```bash
pip install boto3 google-cloud-bigquery pandas pyarrow pandas-gbq
```

### 4. Download and upload data
```bash
# Download NYC Taxi parquet files
# Upload to S3 partitions
python load_to_bq.py
```

### 5. Run dbt
```bash
cd nyc_taxi
dbt run
dbt test
```

---

## Key Results

- **9,384,487** NYC taxi trips processed
- **3 dbt models** created (1 staging view + 2 mart tables)
- **8/8 data quality tests** passing
- **Query cost reduction** via partitioning — scans only relevant year/month slices
- **Zero-touch CI/CD** — full pipeline runs on every `git push`

---


> "I built an end-to-end batch data pipeline processing 9.3 million NYC taxi trips across AWS and GCP. Infrastructure is fully reproducible via Terraform IaC. Data flows from partitioned S3 storage into BigQuery, transformed by dbt with 8 automated quality tests across all mart layers — ensuring no bad data reaches a report. The entire pipeline deploys with a single git push via GitHub Actions."

---

## Author
**Kittin Phm** — Data Engineering Portfolio Project

Built with: Terraform · AWS S3 · GCP BigQuery · dbt · Python · GitHub Actions
