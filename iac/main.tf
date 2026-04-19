terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  credentials = var.credentials_file == null ? null : file(var.credentials_file)
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "terraform_data" "kestra_startup_script" {
  input = {
    startup_script = filemd5("install_kestra.sh")
    docker_compose = filemd5("docker-compose.yml")
  }
}

resource "google_storage_bucket" "raw_data_bucket" {
  name          = "${var.project_id}-raw-data-bucket-${random_id.bucket_suffix.hex}"
  location      = var.location
  force_destroy = var.bucket_force_destroy

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# Recommended datasets for dbt-style layering:
# - raw: ingestion landing tables
# - analytics: dbt-built models (staging/marts/aggregates)
resource "google_bigquery_dataset" "raw" {
  dataset_id = "raw"
  location   = var.location
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id = "analytics"
  location   = var.location
}

# Allow the VM's attached service account (used by Kestra + dbt on the VM)
# to run BigQuery jobs.
resource "google_project_iam_member" "kestra_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.kestra-svc-acc.email}"
}

# Allow writes/creates in the raw + analytics datasets.
resource "google_bigquery_dataset_iam_member" "kestra_raw_data_editor" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.kestra-svc-acc.email}"
}

resource "google_bigquery_dataset_iam_member" "kestra_analytics_data_editor" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.kestra-svc-acc.email}"
}

# Create a VPC network and firewall rule to allow kestra web UI access (port 8080)
resource "google_compute_network" "vpc_network" {
  name                    = "kestra-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "kestra_firewall" {
  name    = "kestra-firewall-rule"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9092"] # 22=SSH, 8080=kestra UI, 9092=kestra broker
  }

  target_tags   = ["kestra-server"]
  source_ranges = ["0.0.0.0/0"] # Replace this with your public IPv4 in /32 CIDR form before deploying publicly, e.g. ["203.0.113.42/32"]. Do not use a local/private IP like 192.168.x.x or 10.x.x.x here.
}

resource "google_service_account" "kestra-svc-acc" {
  account_id   = "kestra-svc-acc"
  display_name = "Custom SVC Acc for VM Instance"
}

# done so kestra vm can upload new files to bucket
resource "google_storage_bucket_iam_member" "kestra_bucket_object_creator" {
  bucket = google_storage_bucket.raw_data_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.kestra-svc-acc.email}"
}

# done for checks/retries
resource "google_storage_bucket_iam_member" "kestra_bucket_object_viewer" {
  bucket = google_storage_bucket.raw_data_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.kestra-svc-acc.email}"
}

resource "google_compute_instance" "kestra-vm" {
  name         = "kestra-vm-aqd"
  machine_type = var.machine_type
  zone         = var.zone

  lifecycle {
    replace_triggered_by = [terraform_data.kestra_startup_script]
  }

  tags = ["kestra-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = google_compute_network.vpc_network.id

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = templatefile("install_kestra.sh", {
    docker_compose = file("docker-compose.yml")
  })

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.kestra-svc-acc.email
    scopes = ["cloud-platform"]
  }
}