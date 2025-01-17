variable "project_id" {
  description = "The project ID"
  type        = string
  default     = "smart-water-plan"
}

variable "project_region" {
  default = "us-central1"
}

variable "project_zone" {
  default = "us-central1-c"
}

variable "schedule" {
  description = "The schedule for the Cloud Scheduler job in cron format"
  type        = string
  default     = "*/3 * * * *" # Every 3 minutes
}