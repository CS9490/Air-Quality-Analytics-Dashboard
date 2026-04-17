variable "project_id" {
  description = "The GCP project ID"
  type        = string
  # Replace with your project ID
  default = "air-quality-analytics-491022"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "The GCP zone (must be within region)"
  type        = string
  default     = "us-east1-b"
}

variable "location" {
  description = "GCP resource location (e.g. US multi-region for BigQuery + GCS)"
  type        = string
  default     = "US"
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "n2-standard-2" # Use a machine type with sufficient resources
}

variable "bucket_force_destroy" {
  description = "Whether to allow Terraform to delete the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "credentials_file" {
  description = "Optional path to a service account JSON key file. If null, uses Application Default Credentials (ADC)."
  type        = string
  default     = null
}