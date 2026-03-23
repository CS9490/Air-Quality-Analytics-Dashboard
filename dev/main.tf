terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.24.0"
    }
  }
}

provider "google" {
  project = "air-quality-analytics-491022"
  region  = "us-east1"

  credentials = file("${path.module}/keys/my-creds.json")
}

resource "google_storage_bucket" "test-bucket" {
  name          = "air-quality-analytics-491022-terra-bucket-test"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "test_dataset" {
  dataset_id = "test_dataset"
  location   = "US"
}