variable "tags" {
  type = map
  description = "The map of tags required for AWS resources."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "environment" {
  type        = string
  description = "The name of the deployment environment, e.g. dev, prod."
}

###################################
# --  OpenCTI Connector Other  -- #
###################################

variable "email_domain" {
  type        = string
  description = "The domain to use for the connector account email."
}

variable "opencti_url" {
  type        = string
  description = "The public Load Balancer endpoint for OpenCTI Platform or the URL."
}

###################################
# -- OpenCTI Connector General -- #
###################################

variable "opencti_version" {
  type        = string
  description = "The version tag of the OpenCTI docker image. Examples include latest or 5.2.4."
}

variable "opencti_platform_url" {
  type        = string
  description = "The internal Load Balancer endpoint for OpenCTI Platform."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "Specifies the number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery. The default value is 30."
}