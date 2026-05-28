provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_bigquery_dataset" "taxi" {
  dataset_id  = var.bq_dataset_name
  description = "NYC Taxi historical trip data"
  location    = var.gcp_region

  default_table_expiration_ms = 7776000000

  labels = {
    project = "nyc-taxi-lakehouse"
    env     = "dev"
  }
}

resource "google_bigquery_table" "raw_trips" {
  dataset_id          = google_bigquery_dataset.taxi.dataset_id
  table_id            = "raw_trips"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "tpep_pickup_datetime"
  }

  schema = jsonencode([
    { name = "VendorID",              type = "INTEGER" },
    { name = "tpep_pickup_datetime",  type = "TIMESTAMP" },
    { name = "tpep_dropoff_datetime", type = "TIMESTAMP" },
    { name = "passenger_count",       type = "INTEGER" },
    { name = "trip_distance",         type = "FLOAT" },
    { name = "PULocationID",          type = "INTEGER" },
    { name = "DOLocationID",          type = "INTEGER" },
    { name = "fare_amount",           type = "FLOAT" },
    { name = "tip_amount",            type = "FLOAT" },
    { name = "total_amount",          type = "FLOAT" }
  ])
}