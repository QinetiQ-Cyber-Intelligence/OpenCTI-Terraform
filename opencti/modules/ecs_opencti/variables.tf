#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy Fargate resources into."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that Fargate resources can be deployed to."
}

variable "public_cidr_blocks" {
  type        = list(string)
  description = "List of the public CIDR Blocks."
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "List of the private CIDR blocks."
}

variable "private_network_load_balancer_dns" {
  type        = string
  description = "The Network Load Balancer private endpoint."
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "The number of days that a Secret in Secrets Manager can be recovered post deletion."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "application_load_balancer_security_group" {
  type        = string
  description = "The Security Group ID attached to the public Application Load Balancer."
}

variable "private_network_load_balancer_static_ips" {
  type        = list(string)
  description = "The Static IP addresses associated with the Private NLB."
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Enable or disable the ECS Exec capability on ECS Fargate instances."
}

########################################
# -- OpenCTI Platform Configuration -- #
########################################
variable "opencti_version" {
  type        = string
  description = "The version tag of the OpenCTI docker image. Examples include latest or 5.2.4."
}

variable "opencti_platform_admin_email" {
  type        = string
  description = "The default admin email for accessing OpenCTI."
}

variable "opencti_logging_level" {
  type        = string
  description = "The level of logging that should take place. In the Dev environment this should be 'info'/'debug', in Prod set to 'error'/'info'."
}

variable "opencti_platform_port" {
  type        = number
  description = "The port that OpenCTI Platform will run on."
}

variable "opencti_platform_service_desired_count" {
  type        = number
  description = "The number of OpenCTI Platform tasks that should be run by default (Subject to autoscaling)."
}

variable "opencti_platform_service_max_count" {
  type        = number
  description = "The maximum number of OpenCTI Platform tasks that can be run through AutoScaling."
}

variable "opencti_platform_service_min_count" {
  type        = number
  description = "The minimum number of OpenCTI Platform tasks that can be run through AutoScaling."
}

variable "opencti_platform_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer Target Group routing traffic to OpenCTI Platform."
}

variable "opencti_platform_application_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Public Target Group for OpenCTI Platform."
}

variable "opencti_platform_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated to an OpenCTI Platform Task."
}

variable "opencti_platform_memory_size" {
  type        = number
  description = "The amount of memory allocated to an OpenCTI Platform Task."
}

variable "oidc_information" {
  type = object({
    client_id              = string
    client_secret          = string
    issuer                 = string
    authorization_endpoint = string
    token_endpoint         = string
    user_info_endpoint     = string
    redirect_uris          = list(string)
    session_timeout        = number
    scope                  = string
    on_unauthenticated_request = string
  })
  description = "The OIDC Authentication information used by OpenCTI Platform and the ALB."
  sensitive   = true
}

variable "opencti_openid_mapping_config" {
  type = object({
    groups_token   = string,
    groups_scope   = string,
    groups_path    = list(string),
    groups_mapping = list(string),
    roles_token    = string,
    roles_scope    = string,
    roles_path     = list(string),
    roles_mapping  = list(string)
  })
  description = "The RBAC mapping information for OpenCTI Platform to use."
}

#######################################
# -- OpenCTI Platform Dependencies -- #
#######################################
variable "opensearch_endpoint_address" {
  type        = string
  description = "The endpoint of the AWS Opensearch instance to upload data to."
}

variable "opensearch_credentials_arn" {
  type        = string
  description = "The Secrets Manager credentials ARN for AWS OpenSearch."
}

variable "opensearch_template_primary_shard_count" {
  type        = number
  description = "The number of Primary Shards that should be used in the OpenCTI Index Template."
}

variable "elasticache_credentials_arn" {
  type        = string
  description = "The Secrets Manger credentials ARN for AWS Elasticache Redis."
}

variable "elasticache_endpoint_address" {
  type        = string
  description = "The Endpoint address for Elasticache redis for Read and Write Ops."
}

variable "elasticache_redis_port" {
  type        = string
  description = "The port that the Redis Cluster will be accessible on."
}

variable "redis_trimming" {
  type        = number
  description = "The amount of events that can exist within a Redis stream before OpenCTI removes older events."
}

######################################
# -- OpenCTI Worker Configuration -- #
######################################
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

variable "opencti_worker_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated to an OpenCTI Worker Task."
}

variable "opencti_worker_memory_size" {
  type        = number
  description = "The amount of memory allocated to an OpenCTI Worker Task."
}

##################
# -- RabbitMQ -- #
##################
variable "rabbitmq_cluster_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ Cluster."
}

variable "rabbitmq_management_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ Management portal."
}

variable "rabbitmq_management_port" {
  type        = number
  description = "The management port for RabbitMQ."
}

variable "rabbitmq_node_port" {
  type        = number
  description = "The AMQP port for RabbitMQ."
}

variable "rabbitmq_image_tag" {
  type        = string
  description = "The Docker Image tag for the RabbitMQ Container."
}

variable "rabbitmq_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated for the RabbitMQ Container."
}

variable "rabbitmq_memory_size" {
  type        = number
  description = "The amount of memory allocated for the RabbitMQ Container."
}

###############
# -- MinIO -- #
###############
variable "minio_s3_bucket_name" {
  type        = string
  description = "The S3 Bucket name used by OpenCTI as an object storage solution."
}

variable "minio_s3_bucket_arn" {
  type        = string
  description = "The S3 Bucket ARN used by OpenCTI as an object storage solution."
}