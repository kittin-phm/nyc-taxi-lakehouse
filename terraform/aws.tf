provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "taxi_raw" {
  bucket = var.aws_bucket_name

  tags = {
    Project     = "nyc-taxi-lakehouse"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "taxi_raw" {
  bucket = aws_s3_bucket.taxi_raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "taxi_raw" {
  bucket = aws_s3_bucket.taxi_raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "partitions" {
  for_each = toset([
    "year=2023/month=01/",
    "year=2023/month=02/",
    "year=2023/month=03/",
    "year=2024/month=01/",
    "year=2024/month=02/",
    "year=2024/month=03/",
  ])

  bucket  = aws_s3_bucket.taxi_raw.id
  key     = each.value
  content = ""
}