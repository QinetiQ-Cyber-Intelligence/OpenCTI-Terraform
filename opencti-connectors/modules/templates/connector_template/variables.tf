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

variable "opencti_connector_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated to an OpenCTI Connector Task by default."
  default     = 512
}

variable "opencti_connector_memory_size" {
  type        = number
  description = "The amount of memory allocated to a OpenCTI Connector Task by default."
  default     = 1024
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

variable "container_name" {
  type        = string
  description = "The name given to the OpenCTI connector."
}

variable "opencti_connector_image" {
  type        = string
  description = "The location on DockerHub or other Docker repo of the OpenCTI connector."
}

variable "environment_variable_def" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}