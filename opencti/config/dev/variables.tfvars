# Default tags to apply to all deployed resources
tags = {
  Company = "Example"
  Department = "Example"
  Environment = "dev"
  Name = "OpenCTI"
  Product = "OpenCTI"
}
# Prefix to prepend to resource names
resource_prefix = "CHANGEME"
# Amount of days to retain logs
# Must be one of [0 1 3 5 7 14 30 60 90 120 150 180 365 400 545 731 1827 3653]
log_retention = 14
# Number of days that AWS Secrets Manager waits before it can delete the secret.
# This value can be 0 to force deletion without recovery or range from 7 to 30 days.
# If you plan to run a terraform destroy for any reason, it is recommended to leave
# this as 0.
secrets_manager_recovery_window = 0
# Update `aws_account_id_lb_logs` to relevant AWS Account ID, see:
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions:~:text=id/*%22%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D-,The,-following%20table%20contains
aws_account_id_lb_logs = "127311923021"
enable_ecs_exec        = true

####################################
# -- Authentication and Domains -- #
####################################
# If using a Route 53 Hosted Zone, define your domains here
# Note: OpenCTI will be accessible at: {subdomain}.{domain}
# Ensure you grab the nameservers for your hosted zone
# in case you are managing the domain in another AWS account
# TODO

# The following variables are used to build the fully qualified domain name
# e.g. OpenCTI endpoint will be accessible at: {subdomain}.{environment}.{domain}
subdomain   = "opencti"
environment = "dev"
domain      = "example.com"

# The ssl policy to use for SSL between clients and the public load balancer
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2020-10"

# (Optional) If using an OpenID Connect IdP, define required configuration data here
# Note: Okta was used at the time and requires the following settings in order for a "Fat Token" to be returned when authorizing
# See this link for more info: https://support.okta.com/help/s/article/Okta-Groups-or-Attribute-Missing-from-Id-Token?language=en_US
oidc_information = {
  client_id              = "CHANGEME" # (Required) OAuth 2.0 client identifier.
  client_secret          = "OIDC_CLIENT_SECRET" # (Required) OAuth 2.0 client secret. Warning: Do not store this in source control.
  issuer                 = "https://example.okta.com" # (Required) OIDC issuer identifier of the IdP.
  token_endpoint         = "https://example.okta.com/oauth2/v1/token" # (Required) Token endpoint of the IdP.
  authorization_endpoint = "https://example.okta.com/oauth2/v1/authorize" # (Required) Authorization endpoint of the IdP.
  user_info_endpoint     = "https://example.okta.com/oauth2/v1/userinfo" # (Required) User info endpoint of the IdP.
  redirect_uris          = ["https://opencti.dev.example.com/auth/oic/callback"] # (Required) The redirect URIs
  session_timeout        = 36000 # (Optional) Maximum duration of the authentication session, in seconds.
  scope                  = "groups profile openid" # Scope for the load balancer request
  # If the user is not authenticated to access the public endpoint
  # Valid values are:
  #   deny: Deny unauthenticated users
  #   authenticate: Redirect user to authenticate (you will need to specify two redirect URIs in your OIDC app, e.g. 
  #                 https://opencti.dev.example.com/oauth2/idpresponse
  #                 https://opencti.dev.example.com/auth/oic/callback
  #   allow: User is able to access the OpenCTI login page
  on_unauthenticated_request = "authenticate"
}
opencti_openid_mapping_config = {
  groups_token   = "id_token"
  groups_scope   = "groups profile"
  groups_path    = ["groups"]
  # Map of OpenID_Group_Name:OpenCTI_Group
  groups_mapping = ["okta-group-1:opencti-group-1", "okta-group-2:opencti-group-2"]
  roles_token   = "id_token"
  roles_scope   = "groups profile"
  roles_path    = ["groups"]
  # Map of OpenID_Group_Name:OpenCTI_Role
  roles_mapping = ["okta-group-1:opencti-role-1", "okta-group-1:opencti-role-2"]
}

####################
# -- OpenSearch -- #
####################
# If you run into this issue try to increase opensearch_auto_tune.length:
# Error creating OpenSearch domain: ValidationException:
# The StartAt time you provided occurs in the past. 
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
  length     = "48h"
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

# Allow inbound access to all (default)
# Change this to allow only certain IP addresses
# from accessing the public endpoint for OpenCTI
# It is advised to set oidc_information.on_unauthenticated_request to "authenticate",
# if you decide to leave this setting as 0.0.0.0/0 (inbound to all)
# and then set cidr_blocks_bypass_auth to specific whitelisted IP addresses
# This will allow you to block all public access without authentication
# and still be able to call the API or access the UI from whitelisted IPs
cidr_blocks_public_lb_ingress = [
  "0.0.0.0/0"
]
# If you need to bypass oidc (if configured), e.g. access the OpenCTI API without OIDC auth from trusted sources,
# specify the cidr ranges here
cidr_blocks_bypass_auth = []

############################
# -- OpenCTI Deployment -- #
############################

# -- OpenCTI -- #
opencti_version                      = "5.3.15" # or 5.3.8 and greater
public_opencti_access_logs_s3_prefix = "CHANGEME-opencti-access-logs-dev"
# -- OpenCTI Platform -- #
opencti_platform_port                  = 4000
opencti_platform_service_desired_count = 1
# OpenCTI Platform autoscaling is not setup as part of this deployment, but can be setup quickly with Step Scaling or Target Tracking.
opencti_platform_service_max_count = 1
opencti_platform_service_min_count = 1
opencti_platform_admin_email       = "opencti+dev@example.com"
opencti_logging_level              = "debug"
opencti_platform_cpu_size          = 2048
opencti_platform_memory_size       = 4096

# -- OpenCTI Worker -- #
opencti_worker_service_desired_count = 1
opencti_worker_service_max_count     = 6
opencti_worker_service_min_count     = 1
opencti_worker_cpu_size              = 256
opencti_worker_memory_size           = 512

############################
# -- Jumpbox Deployment -- #
############################

# Optionally deploy an SSM "jump box" that runs in the VPC
# Note: requires iam:CreateRole permissions
enable_jump_box = false
