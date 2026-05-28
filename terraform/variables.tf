variable "aws_bucket_name" {
  type    = string
  default = "nyc-taxi-raw-kittinphm"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "gcp_project_id" {
  type    = string
  default = "nyc-taxi-lakehouse-497608"
}

variable "gcp_region" {
  type    = string
  default = "asia-southeast1"
}

variable "bq_dataset_name" {
  type    = string
  default = "nyc_taxi"
}