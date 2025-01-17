terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.project_region
  zone    = var.project_zone
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "cloud-function-${random_id.default.hex}" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "npm install && npm run build"
  }
}

resource "null_resource" "zip" {
  depends_on = [null_resource.build]
  provisioner "local-exec" {
    command = "zip -r /tmp/function-source.zip dist"
  }
}

data "archive_file" "default" {
  depends_on  = [null_resource.zip]
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "../dist"
}
resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "default" {
  name        = "function-v2"
  location    = "us-central1"
  description = "a new function"

  build_config {
    runtime     = "nodejs22"
    entry_point = "helloHttp" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Scheduler Job
resource "google_cloud_scheduler_job" "default" {
  name        = "example-http-job"
  description = "A scheduled job to trigger an HTTP endpoint"
  schedule    = var.schedule       # E.g., "*/3 * * * *" for every 3 minutes
  time_zone        = "America/New_York"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.default.service_config[0].uri
  }
  depends_on = [google_cloudfunctions2_function.default] # Ensure function is ready
}