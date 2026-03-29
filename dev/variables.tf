variable "project_id" {
  description = "The GCP project ID"
  type        = string
  # Replace with your project ID
  default = "your-gcp-project-id"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "e2-standard-4" # Use a machine type with sufficient resources
}