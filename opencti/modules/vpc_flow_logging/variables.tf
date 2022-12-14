#################
# -- General -- #
#################
variable "vpc_id" {
  type        = string
  description = "The VPC ID to perform VPC Flow logging on."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS Key used for encryption."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}