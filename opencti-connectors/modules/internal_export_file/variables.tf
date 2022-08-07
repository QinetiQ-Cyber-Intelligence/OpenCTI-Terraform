variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

###################################
# -- OpenCTI Connector General -- #
###################################

variable "opencti_version" {
  type        = string
  description = "The version tag of the OpenCTI docker image. Examples include latest or 5.2.4."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The Private Subnets that an OpenCTI Connector can be deployed to."
}

variable "ecs_cluster" {
  type        = string
  description = "The ID of the ECS Cluster to deploy to."
}

variable "connector_security_group_id" {
  type        = string
  description = "The default Security Group to be used by Connectors."
}

variable "opencti_platform_url" {
  type        = string
  description = "The internal Load Balancer endpoint for OpenCTI Platform."
}

variable "opencti_connector_kms_arn" {
  type        = string
  description = "The ARN value of the KMS Key used to encrypt Connector API Key Secrets."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "halt_connector_lambda_arn" {
  type        = string
  default     = ""
  description = "If the Connector is scheduled, the ARN value of the Lambda function to be used by AWS EventBridge."
}


######################################
# -- OpenCTI Connector Export PDF -- #
######################################

variable "in_exp_pdf_connector_name" {
  type        = string
  description = "The name given to the PDF Internal Export connector."
}

variable "in_exp_pdf_connector_image" {
  type        = string
  description = "The location on DockerHub of the PDF Internal Export connector."
}