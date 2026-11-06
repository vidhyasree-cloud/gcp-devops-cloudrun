# Terraform for the GCP DevOps project — Cloud Run CI/CD
# Personal portfolio project. Free-trial / $300 credit only.
# Set a budget alert FIRST (see README), delete resources after each lab.
# Cloud SQL is NOT in this project — it has no Always Free tier.
# Usage:
#   terraform init
#   terraform plan -var="project_id=YOUR_PROJECT_ID" -var="region=us-central1"
#   terraform apply -var="project_id=YOUR_PROJECT_ID" -var="region=us-central1"
#   terraform destroy   # <-- run this after each lab session

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "us-central1"
}
variable "service_name" {
  type    = string
  default = "capacity-estimator"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
  ])
  service = each.value
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.service_name
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

resource "google_secret_manager_secret" "app_secret" {
  secret_id = "capacity-estimator-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      # First deploy is done by Cloud Build; Terraform manages the service.
      # Replace this image with your Artifact Registry image after the first build.
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.service_name}/${var.service_name}:latest"
      ports {
        container_port = 8080
      }
      env {
        name  = "APP_ENV"
        value = "prod"
      }
    }
  }
  depends_on = [google_project_service.apis]
}

# Public (unauthenticated) access for this learning demo only.
# For a real service, remove this and use IAM / IAP instead.
resource "google_cloud_run_v2_service_iam_member" "public" {
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_v2_service.service.uri
}
output "artifact_registry" {
  value = google_artifact_registry_repository.repo.name
}
