################################
# -- Fundamental Networking -- #
# --       components       -- #
################################
data "aws_region" "current" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  #checkov:skip=CKV2_AWS_11:VPC Flow Logs are instead configured inside of a dedicated optional module.
  tags = {
    Name = "${var.resource_prefix}-vpc"
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# -- MinIO -- #
resource "aws_vpc_endpoint" "this" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

############################
# -- Networking Modules -- #
############################

# module "aws_flow_logging" {
#   source          = "./modules/vpc_flow_logging"
#   resource_prefix = var.resource_prefix
#   vpc_id          = aws_vpc.this.id
#   log_retention   = var.log_retention
# }

module "az_a_networking" {
  source                = "./modules/az_subnet"
  vpc_id                = aws_vpc.this.id
  vpc_s3_endpoint_id    = aws_vpc_endpoint.this.id
  resource_prefix       = var.resource_prefix
  private_subnet_cidr   = var.az_a_private_cidr
  public_subnet_cidr    = var.az_a_public_cidr
  public_route_table_id = aws_route_table.public.id
  availability_zone     = "${data.aws_region.current.name}a"
  depends_on            = [aws_internet_gateway.this]
}

module "az_b_networking" {
  source                = "./modules/az_subnet"
  vpc_id                = aws_vpc.this.id
  vpc_s3_endpoint_id    = aws_vpc_endpoint.this.id
  resource_prefix       = var.resource_prefix
  private_subnet_cidr   = var.az_b_private_cidr
  public_subnet_cidr    = var.az_b_public_cidr
  public_route_table_id = aws_route_table.public.id
  availability_zone     = "${data.aws_region.current.name}b"
  depends_on            = [aws_internet_gateway.this]
}

module "az_c_networking" {
  source                = "./modules/az_subnet"
  vpc_id                = aws_vpc.this.id
  vpc_s3_endpoint_id    = aws_vpc_endpoint.this.id
  resource_prefix       = var.resource_prefix
  private_subnet_cidr   = var.az_c_private_cidr
  public_subnet_cidr    = var.az_c_public_cidr
  public_route_table_id = aws_route_table.public.id
  availability_zone     = "${data.aws_region.current.name}c"
  depends_on            = [aws_internet_gateway.this]
}

module "jump_box" {
  count           = var.enable_jump_box ? 1 : 0 
  source          = "./modules/ssm_jump"
  vpc_id          = aws_vpc.this.id
  resource_prefix = var.resource_prefix
  private_subnet_ids = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id
  ]
}

module "load_balancing" {
  source = "./modules/load_balancing"
  # -- General -- #
  resource_prefix = var.resource_prefix
  vpc_id          = aws_vpc.this.id
  environment     = var.environment
  domain          = var.domain
  subdomain       = var.subdomain
  ssl_policy      = var.ssl_policy
  private_subnet_ids = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id
  ]
  public_subnet_ids = [
    module.az_a_networking.public_subnet_id,
    module.az_b_networking.public_subnet_id,
    module.az_c_networking.public_subnet_id
  ]
  private_cidr_blocks = [
    var.az_a_private_cidr,
    var.az_b_private_cidr,
    var.az_c_private_cidr
  ]
  network_load_balancer_ips            = var.network_load_balancer_ips
  opencti_platform_port                = var.opencti_platform_port
  rabbitmq_node_port                   = var.rabbitmq_node_port
  rabbitmq_management_port             = var.rabbitmq_management_port
  logging_s3_bucket                    = module.s3.logging_s3_bucket
  public_opencti_access_logs_s3_prefix = var.public_opencti_access_logs_s3_prefix
  oidc_information                     = var.oidc_information
  cidr_blocks_public_lb_ingress        = var.cidr_blocks_public_lb_ingress
  cidr_blocks_bypass_auth              = var.cidr_blocks_bypass_auth
}

#################################################
# -- Backend AWS Services supporting OpenCTI -- #
#################################################
# Understanding Elasticache Redis
# A single node group with multiple read replicas is used.
# This creates a Primary Node that handles read/write and a number of replicas that contain 'backups'
# of the current cache. If the Primary Node were to fail over, AWS handles the automatic promotion of a read node
# to take on the role of Primary Node. This ensures data redundancy as the nodes are spread across AZs.
module "elasticache" {
  # AWS ElastiCache for Redis, used for in-memory caching such as session tokens, computation etc.
  source = "./modules/elasticache"
  # -- General -- #
  resource_prefix = var.resource_prefix
  vpc_id          = aws_vpc.this.id
  private_cidr_blocks = [
    var.az_a_private_cidr,
    var.az_b_private_cidr,
    var.az_c_private_cidr
  ]
  private_subnet_ids = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id
  ]
  secrets_manager_recovery_window = var.secrets_manager_recovery_window
  # -- Redis -- #
  elasticache_instance_type                  = var.elasticache_instance_type
  elasticache_replication_count              = var.elasticache_replication_count
  elasticache_redis_port                     = var.elasticache_redis_port
  elasticache_redis_version                  = var.elasticache_redis_version
  elasticache_redis_snapshot_retention_limit = var.elasticache_redis_snapshot_retention_limit
  elasticache_redis_snapshot_time            = var.elasticache_redis_snapshot_time
  elasticache_redis_maintenance_period       = var.elasticache_redis_maintenance_period
  accepted_security_group_ids = ((var.enable_jump_box)) ? [
    module.opencti.opencti_platform_security_group,
    module.jump_box.jump_box_security_group
  ] : [
    module.opencti.opencti_platform_security_group
  ]
  # Ensure that the NLB IP Address is not taken
  depends_on = [
    module.load_balancing.network_load_balancer_subnet_mapping
  ]

}

module "s3" {
  source                               = "./modules/s3"
  resource_prefix                      = var.resource_prefix
  public_opencti_access_logs_s3_prefix = var.public_opencti_access_logs_s3_prefix
  aws_account_id_lb_logs               = var.aws_account_id_lb_logs
}

module "opensearch" {
  source = "./modules/opensearch"
  # -- General -- #
  vpc_id      = aws_vpc.this.id
  private_cidr_blocks = [
    var.az_a_private_cidr,
    var.az_b_private_cidr,
    var.az_c_private_cidr
  ]
  private_subnet_ids = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id
  ]
  resource_prefix                 = var.resource_prefix
  secrets_manager_recovery_window = var.secrets_manager_recovery_window
  # -- OpenSearch -- #
  opensearch_engine_version           = var.opensearch_engine_version
  opensearch_master_count             = var.opensearch_master_count
  opensearch_master_instance_type     = var.opensearch_master_instance_type
  opensearch_data_node_instance_type  = var.opensearch_data_node_instance_type
  opensearch_data_node_instance_count = var.opensearch_data_node_instance_count
  opensearch_warm_instance_type       = var.opensearch_warm_instance_type
  opensearch_warm_count               = var.opensearch_warm_count
  opensearch_ebs_volume_size          = var.opensearch_ebs_volume_size
  opensearch_field_data_heap_usage    = var.opensearch_field_data_heap_usage
  opensearch_auto_tune                = var.opensearch_auto_tune
  log_retention                       = var.log_retention
  accepted_security_group_ids = ((var.enable_jump_box)) ? [
    module.opencti.opencti_platform_security_group,
    module.jump_box.jump_box_security_group
  ] : [
    module.opencti.opencti_platform_security_group
  ]
  # Ensure that the NLB IP Address is not taken
  depends_on = [
    module.load_balancing.network_load_balancer_subnet_mapping
  ]
}

##################################
# -- OpenCTI Deployment (ECS) -- #
##################################

module "opencti" {
  source = "./modules/ecs_opencti"
  # -- General -- #
  resource_prefix = var.resource_prefix
  private_subnet_ids = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id
  ]
  vpc_id                            = aws_vpc.this.id
  private_network_load_balancer_dns = module.load_balancing.private_network_load_balancer_dns
  private_cidr_blocks = [
    var.az_a_private_cidr,
    var.az_b_private_cidr,
    var.az_c_private_cidr
  ]
  public_cidr_blocks = [
    var.az_a_public_cidr,
    var.az_b_public_cidr,
    var.az_c_public_cidr
  ]
  secrets_manager_recovery_window          = var.secrets_manager_recovery_window
  log_retention                            = var.log_retention
  application_load_balancer_security_group = module.load_balancing.application_load_balancer_security_group
  private_network_load_balancer_static_ips = var.network_load_balancer_ips
  enable_ecs_exec                          = var.enable_ecs_exec
  # -- OpenCTI -- #
  opencti_version                                             = var.opencti_version
  opencti_platform_port                                       = var.opencti_platform_port
  opencti_platform_service_desired_count                      = var.opencti_platform_service_desired_count
  opencti_platform_service_max_count                          = var.opencti_platform_service_max_count
  opencti_platform_service_min_count                          = var.opencti_platform_service_min_count
  opencti_platform_admin_email                                = var.opencti_platform_admin_email
  opencti_platform_application_load_balancer_target_group_arn = module.load_balancing.opencti_platform_application_load_balancer_target_group_arn
  opencti_platform_load_balancer_target_group_arn             = module.load_balancing.opencti_platform_load_balancer_target_group_arn
  opencti_logging_level                                       = var.opencti_logging_level
  opencti_platform_cpu_size                                   = var.opencti_platform_cpu_size
  opencti_platform_memory_size                                = var.opencti_platform_memory_size
  opencti_openid_mapping_config                               = var.opencti_openid_mapping_config
  oidc_information                                            = var.oidc_information

  opencti_worker_service_desired_count = var.opencti_worker_service_desired_count
  opencti_worker_service_max_count     = var.opencti_worker_service_max_count
  opencti_worker_service_min_count     = var.opencti_worker_service_min_count
  opencti_worker_memory_size           = var.opencti_worker_memory_size
  opencti_worker_cpu_size              = var.opencti_worker_cpu_size
  # -- OpenSearch -- #
  opensearch_endpoint_address             = module.opensearch.opensearch_endpoint_address
  opensearch_credentials_arn              = module.opensearch.opensearch_credentials_arn
  opensearch_template_primary_shard_count = var.opensearch_template_primary_shard_count
  # -- Elasticache -- #
  elasticache_endpoint_address = module.elasticache.elasticache_endpoint_address
  elasticache_redis_port       = var.elasticache_redis_port
  elasticache_credentials_arn  = module.elasticache.elasticache_credentials_arn
  redis_trimming               = var.redis_trimming
  # -- RabbitMQ -- #
  rabbitmq_node_port                                 = var.rabbitmq_node_port
  rabbitmq_cluster_load_balancer_target_group_arn    = module.load_balancing.rabbitmq_cluster_load_balancer_target_group_arn
  rabbitmq_management_load_balancer_target_group_arn = module.load_balancing.rabbitmq_management_load_balancer_target_group_arn
  rabbitmq_management_port                           = var.rabbitmq_management_port
  rabbitmq_image_tag                                 = var.rabbitmq_image_tag
  rabbitmq_cpu_size                                  = var.rabbitmq_cpu_size
  rabbitmq_memory_size                               = var.rabbitmq_memory_size
  # -- MinIO -- #
  minio_s3_bucket_name = module.s3.minio_s3_bucket_name
  minio_s3_bucket_arn  = module.s3.minio_s3_bucket_arn
  depends_on = [
    module.az_a_networking.private_subnet_id,
    module.az_b_networking.private_subnet_id,
    module.az_c_networking.private_subnet_id,
    # Ensure that the NLB IP Address is not taken
    module.load_balancing.network_load_balancer_subnet_mapping
  ]
}
