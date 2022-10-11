#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "public_opencti_access_logs_s3_prefix" {
  type        = string
  description = "The Prefix assigned to the S3 Bucket for public ALB Access Logs."
}

variable "aws_account_id_lb_logs" {
  type        = string
  description = "The AWS-owned Account ID that is required to push access logs to the S3 Bucket."
}
