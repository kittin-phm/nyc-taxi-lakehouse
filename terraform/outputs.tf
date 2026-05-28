output "s3_bucket_name" {
  value = aws_s3_bucket.taxi_raw.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.taxi_raw.arn
}

output "bigquery_dataset_id" {
  value = google_bigquery_dataset.taxi.dataset_id
}