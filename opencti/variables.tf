#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "tags" {
  type = object({
    ProjectOwner = string
    Customer     = string
    Project      = string
    Environment  = string
    Terraform    = bool
  })
  description = "The set of tags required for AWS resources."
}

variable "domain" {
  type        = string
  description = "The name of the R53 Domain to be used by the ALB."
}

variable "oidc_information" {
  type = object({
    authorization_endpoint = string,
    client_id              = string,
    client_secret          = string,
    issuer                 = string,
    token_endpoint         = string,
    user_info_endpoint     = string,
    redirect_uris          = string
  })
  description = "The OIDC Authentication information used by OpenCTI Platform and the ALB."
  sensitive   = true
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "The number of days that a Secret in Secrets Manager can be recovered post deletion."
}

variable "opencti_connector_names" {
  type        = list(string)
  description = "A list of Connectors that require a Secrets Manager Secret to be deployed to store OpenCTI Tokens."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "aws_account_id_lb_logs" {
  type        = string
  description = "The AWS-owned Account ID that is required to push access logs to the S3 Bucket."
}

variable "public_opencti_access_logs_s3_prefix" {
  type        = string
  description = "The Prefix assigned to the S3 Bucket for public ALB Access Logs."
}

variable "opencti_kms_key_admin" {
  type        = string
  description = "The allowed IAM Entity that can perform administrative tasks on the KMS Key. Root account is allowed."
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Enable or disable the ECS Exec capability on ECS Fargate instances."
}

##########################
# -- OpenCTI Platform -- #
##########################

variable "opencti_version" {
  type        = string
  description = "The version tag of the OpenCTI docker image. Examples include latest or 5.2.4."
}
variable "opencti_platform_admin_email" {
  type        = string
  description = "The default admin email for accessing OpenCTI."
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

variable "opencti_platform_port" {
  type        = number
  description = "The port that OpenCTI Platform will run on."
}

variable "opencti_logging_level" {
  type        = string
  description = "The level of logging that should take place. In the Dev environment this should be 'info'/'debug', in Prod set to 'error'/'info'."
}

variable "opencti_platform_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated to an OpenCTI Platform Task."
}

variable "opencti_platform_memory_size" {
  type        = number
  description = "The amount of memory allocated to an OpenCTI Platform Task."
}

variable "opencti_openid_mapping_config" {
  type = object({
    chosen_token           = string
    oidc_group_claim_path  = string,
    requested_scopes       = string
    opencti_roles_mapping  = string,
    opencti_groups_mapping = string,
  })
  description = "The RBAC mapping information for OpenCTI Platform to use."
}

variable "redis_trimming" {
  type        = number
  description = "The amount of events that can exist within a Redis stream before OpenCTI removes older events."
}

########################
# -- OpenCTI Worker -- #
########################
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

####################
# -- OpenSearch -- #
####################

variable "opensearch_master_instance_type" {
  type        = string
  description = "The instance type to use for master nodes in the OpenSearch domain."
}

variable "opensearch_master_count" {
  type        = string
  description = "The number of master nodes to use for the OpenSearch domain."
}

variable "opensearch_data_node_instance_count" {
  type        = string
  description = "The number of data nodes to use for the OpenSearch domain."
}

variable "opensearch_data_node_instance_type" {
  type        = string
  description = "The instance type to use for the data nodes in the OpenSearch domain."
}

variable "opensearch_warm_count" {
  type        = string
  description = "The number of warm nodes to use for the OpenSearch domain."
}

variable "opensearch_warm_instance_type" {
  type        = string
  description = "The instance type to use for the warm nodes in the OpenSearch domain."
}

variable "opensearch_engine_version" {
  type        = string
  description = "The engine version of the OpenSearch domain."
}

variable "opensearch_ebs_volume_size" {
  type        = number
  description = "The GB size of the EBS Volume for each OpenSearch data node."
}

variable "opensearch_field_data_heap_usage" {
  type        = string
  description = "The amount of JVM Heap that Field Data caching can use."
}

variable "opensearch_auto_tune" {
  type = object({
    start_time = string
    length     = string
  })
  description = "The configuration options for AWS OpenSearch Auto Tune."
}

variable "opensearch_template_primary_shard_count" {
  type        = number
  description = "The number of Primary Shards that should be used in the OpenCTI Index Template."
}

#####################
# -- Elasticache -- #
#####################
variable "elasticache_instance_type" {
  type        = string
  description = "The instance type to host Elasticache on."
}

variable "elasticache_redis_version" {
  type        = string
  description = "The Redis version to be used for AWS ElastiCache."
}

variable "elasticache_redis_port" {
  type        = string
  description = "The port that the Redis Cluster will be accessible on."
}

variable "elasticache_replication_count" {
  type        = string
  description = "The number of replicated ElastiCache nodes."
}

variable "elasticache_redis_snapshot_retention_limit" {
  type        = number
  description = "The number of days that ElastiCache Redis will retain automatic snapshots for before deleting them."
}

variable "elasticache_redis_snapshot_time" {
  type        = string
  description = "The time of day that ElastiCache Redis will start a snapshot of a read replica."
}

variable "elasticache_redis_maintenance_period" {
  type        = string
  description = "The time and day that ElastiCache Redis will begin performing maintenance tasks."
}

##################
# -- RabbitMQ -- #
##################
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

####################
# -- Networking -- #
####################
variable "az_a_private_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's private subnet."
}

variable "az_a_public_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's public subnet."
}

variable "az_b_private_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's private subnet."
}

variable "az_b_public_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's public subnet."
}

variable "az_c_private_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's private subnet."
}

variable "az_c_public_cidr" {
  type        = string
  description = "The CIDR block used for this AZ's public subnet."
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR Block for the VPC."
}

variable "network_load_balancer_ips" {
  type        = list(string)
  description = "A list of static IP addresses to be used by the NLB."
}