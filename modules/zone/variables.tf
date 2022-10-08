variable "resource_suffix" {
  type = string
}

variable "location" {
  type = string
}

variable "zone" {
  type = string
}

variable "address_space" {
  type = string
}

variable "remote_virtual_network_id" {
  type = string
}

variable "firewall_policy_id" {
  type = string
}

variable "log_analytics_workspace_daily_quota_gb" {
  type = number
}

variable "log_analytics_workspace_retention_in_days" {
  type = number
}
