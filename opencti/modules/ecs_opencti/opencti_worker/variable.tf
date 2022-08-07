#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy OpenCTI Worker into."
}

variable "ecs_cluster" {
  type        = string
  description = "The ARN Value of the AWS ECS Cluster for OpenCTI."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS Key used for encryption."
}

variable "opencti_platform_url" {
  type        = string
  description = "The Network Load Balancer endpoint used to access OpenCTI Platform."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that Fargate resources can be deployed to."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "rabbitmq_queue_metric_name" {
  type        = string
  default     = "RabbitMQ Total Messages"
  description = "The name given to the CloudWatch metric that lists the total number of messages."
}

variable "rabbitmq_metric_namespace" {
  type        = string
  default     = "OpenCTI RabbitMQ"
  description = "The name given to the CloudWatch namespace for RabbitMQ metrics."
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Enable or disable the ECS Exec capability on ECS Fargate instances."
}

######################################
# -- OpenCTI Worker Configuration -- #
######################################
variable "opencti_version" {
  type        = string
  description = "The version tag of the OpenCTI docker image. Examples include latest or 5.2.4."
}

variable "opencti_worker_service_desired_count" {
  type        = number
  description = "The number of OpenCTI Workers that are desired."
}

variable "opencti_worker_service_max_count" {
  type        = number
  description = "The maximum number of OpenCTI Worker tasks that can be run through AutoScaling."
}

variable "opencti_worker_service_min_count" {
  type        = number
  description = "The minimum number of OpenCTI Worker tasks that can be run through AutoScaling."
}

variable "opencti_platform_token" {
  type        = string
  description = "The Secrets Manager Credential ARN containing the OpenCTI Platform API Key."
}

variable "opencti_worker_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated to an OpenCTI Worker Task."
}

variable "opencti_worker_memory_size" {
  type        = number
  description = "The amount of memory allocated to an OpenCTI Worker Task."
}

variable "opencti_logging_level" {
  type        = string
  description = "The level of logging that should take place. In the Dev environment this should be 'info'/'debug', in Prod set to 'error'/'info'."
}
