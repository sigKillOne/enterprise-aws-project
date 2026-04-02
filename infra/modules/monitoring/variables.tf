# infra/modules/monitoring/variables.tf

variable "app_server_id" {
  description = "The ID of the EC2 instance we want to monitor"
  type        = string
}

variable "alert_email" {
  description = "The email address to send the CPU spike alerts to"
  type        = string
}
