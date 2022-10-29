tags = {
  ProjectOwner = "Undefined"
  Customer     = "Undefined"
  Project      = "OpenCTI"
  Company      = "Undefined"
  Environment  = "dev"
  Terraform    = true
}
resource_prefix = "tf-opencti"

secrets_manager_recovery_window = 0
log_retention                   = 1
# Update `aws_account_id_lb_logs` to relevant AWS Account ID
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions:~:text=id/*%22%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D-,The,-following%20table%20contains
aws_account_id_lb_logs = "127311923021"
opencti_kms_key_admin  = "" # Restrict to a specific IAM Entity
enable_ecs_exec        = true

####################################
# -- Authentication and Domains -- #
####################################
# If using a Route 53 Hosted Zone, define your domain here and uncomment relevant code (discussed in the `README.md`)
domain = ""

# If using an OpenID Connect IdP, define required configuration data here and uncomment relevant code (discussed in the `README.md`)
oidc_information = {
  client_id              = "",
  client_secret          = "",
  issuer                 = "",
  token_endpoint         = "",
  authorization_endpoint = "",
  user_info_endpoint     = "",
  redirect_uris          = "[\"https://opencti.<domain>/auth/oic/callback\"]"
}
opencti_openid_mapping_config = {
  chosen_token           = "id_token"
  oidc_group_claim_path  = "[\"groups\"]"
  opencti_roles_mapping  = "[\"OpenCTI Users:Administrator\"]"
  opencti_groups_mapping = "[\"OpenCTI Users:Administrator\"]"
  requested_scopes       = "groups"
}


####################
# -- OpenSearch -- #
####################
opensearch_engine_version               = "OpenSearch_1.3"
opensearch_master_count                 = 3
opensearch_master_instance_type         = "t3.small.search" # Production = m6g.large.search
opensearch_data_node_instance_count     = 3
opensearch_data_node_instance_type      = "t3.small.search" # Production = r6g.large.search
opensearch_template_primary_shard_count = 2                 # We recommend 2 Primary Shards per index to allow for horizontal scaling across data nodes
# If OpenSearch Warm Data nodes are used, uncomment relevant code in the OpenSearch module main.tf
opensearch_warm_count         = 0
opensearch_warm_instance_type = ""
# Depends on instance type
opensearch_ebs_volume_size       = 15
opensearch_field_data_heap_usage = "40" # Must be a string
opensearch_auto_tune = {
  start_time = "cron(0 7 ? * 7 *)"
  length     = "6h"
}

#####################
# -- Elasticache -- #
#####################
elasticache_instance_type                  = "cache.t4g.small"
elasticache_replication_count              = 1
elasticache_redis_version                  = "6.2"
elasticache_redis_port                     = "6379"
elasticache_redis_snapshot_retention_limit = 1
elasticache_redis_snapshot_time            = "18:00-20:00"
elasticache_redis_maintenance_period       = "sun:21:00-sun:23:00"
redis_trimming                             = 200000 # Based off analysis

##################
# -- RabbitMQ -- #
##################
rabbitmq_management_port = 15672 # Do not change as the default can not be overridden
rabbitmq_node_port       = 5672
rabbitmq_image_tag       = "3.10-management"
rabbitmq_cpu_size        = 1024
rabbitmq_memory_size     = 2048

####################
# -- Networking -- #
####################
vpc_cidr          = "10.5.0.0/16"
az_a_public_cidr  = "10.5.10.0/24"
az_a_private_cidr = "10.5.11.0/24"
az_b_public_cidr  = "10.5.12.0/24"
az_b_private_cidr = "10.5.13.0/24"
az_c_public_cidr  = "10.5.14.0/24"
az_c_private_cidr = "10.5.15.0/24"

network_load_balancer_ips = [
  "10.5.11.60",
  "10.5.13.60",
  "10.5.15.60"
]

############################
# -- OpenCTI Deployment -- #
############################

# -- OpenCTI -- #
opencti_version                      = "5.3.8"
public_opencti_access_logs_s3_prefix = "opencti-access-logs"
# -- OpenCTI Platform -- #
opencti_platform_port                  = 4000
opencti_platform_service_desired_count = 1
# OpenCTI Platform autoscaling is not setup as part of this deployment, but can be setup quickly with Step Scaling or Target Tracking.
opencti_platform_service_max_count = 1
opencti_platform_service_min_count = 1
opencti_platform_admin_email       = "test-opencti@opencti.com"
opencti_logging_level              = "error"
opencti_platform_cpu_size          = 2048
opencti_platform_memory_size       = 4096

# -- OpenCTI Worker -- #
opencti_worker_service_desired_count = 1
opencti_worker_service_max_count     = 6
opencti_worker_service_min_count     = 1
opencti_worker_cpu_size              = 256
opencti_worker_memory_size           = 512

# -- OpenCTI Connectors -- #
opencti_connector_names = [
  "external-import-opencti",
  "external-import-mitre",
  "external-import-cve"
]