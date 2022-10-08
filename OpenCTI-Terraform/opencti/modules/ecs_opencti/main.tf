#################################
# -- AWS ECS OpenCTI Cluster -- #
#################################
# Configurations for quicker ECS deployments and blue-green
# https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/deployment.html
# https://nathanpeck.com/speeding-up-amazon-ecs-container-deployments/
resource "aws_ecs_cluster" "this" {
  name = "${var.resource_prefix}-cluster"

  configuration {
    # Can be updated to S3 bucket logging instead
    execute_command_configuration {
      logging    = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.this.name
      }
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# CloudWatch Cluster Logging
resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}-cluster"
  retention_in_days = var.log_retention
}

module "opencti_platform" {
  source = "./opencti_platform"
  # -- General -- #
  ecs_cluster                              = aws_ecs_cluster.this.id
  resource_prefix                          = var.resource_prefix
  private_subnet_ids                       = var.private_subnet_ids
  vpc_id                                   = var.vpc_id
  private_cidr_blocks                      = var.private_cidr_blocks
  public_cidr_blocks                       = var.public_cidr_blocks
  private_network_load_balancer_dns        = var.private_network_load_balancer_dns
  public_load_balancer_target_group_arn    = var.opencti_platform_application_load_balancer_target_group_arn
  secrets_manager_recovery_window          = var.secrets_manager_recovery_window
  log_retention                            = var.log_retention
  private_network_load_balancer_static_ips = var.private_network_load_balancer_static_ips
  enable_ecs_exec                          = var.enable_ecs_exec
  # -- OpenCTI -- #
  opencti_version                                 = var.opencti_version
  opencti_logging_level                           = var.opencti_logging_level
  opencti_platform_load_balancer_target_group_arn = var.opencti_platform_load_balancer_target_group_arn
  opencti_platform_port                           = var.opencti_platform_port
  opencti_platform_service_desired_count          = var.opencti_platform_service_desired_count
  opencti_platform_service_max_count              = var.opencti_platform_service_max_count
  opencti_platform_service_min_count              = var.opencti_platform_service_min_count
  opencti_platform_admin_email                    = var.opencti_platform_admin_email
  opencti_platform_cpu_size                       = var.opencti_platform_cpu_size
  opencti_platform_memory_size                    = var.opencti_platform_memory_size
  opencti_openid_mapping_config                   = var.opencti_openid_mapping_config
  oidc_information                                = var.oidc_information
  # -- SG IDs -- #
  application_load_balancer_security_group = var.application_load_balancer_security_group
  # -- OpenSearch -- #
  opensearch_endpoint_address             = var.opensearch_endpoint_address
  opensearch_credentials_arn              = var.opensearch_credentials_arn
  opensearch_template_primary_shard_count = var.opensearch_template_primary_shard_count
  # -- ElastiCache -- #
  elasticache_endpoint_address = var.elasticache_endpoint_address
  elasticache_credentials_arn  = var.elasticache_credentials_arn
  elasticache_redis_port       = var.elasticache_redis_port
  redis_trimming               = var.redis_trimming
  # -- RabbitMQ -- #
  rabbitmq_node_port       = var.rabbitmq_node_port
  rabbitmq_management_port = var.rabbitmq_management_port
  rabbitmq_credentials_arn = module.rabbitmq.rabbitmq_credentials_arn
  # -- MinIO -- #
  minio_s3_bucket_name = var.minio_s3_bucket_name
  minio_s3_bucket_arn  = var.minio_s3_bucket_arn
}

module "opencti_worker" {
  source                 = "./opencti_worker"
  ecs_cluster            = aws_ecs_cluster.this.id
  vpc_id                 = var.vpc_id
  resource_prefix        = var.resource_prefix
  log_retention          = var.log_retention
  private_subnet_ids     = var.private_subnet_ids
  opencti_platform_token = module.opencti_platform.opencti_platform_token
  opencti_platform_url   = "http://${var.private_network_load_balancer_dns}:${var.opencti_platform_port}"
  opencti_logging_level  = var.opencti_logging_level
  enable_ecs_exec        = var.enable_ecs_exec

  opencti_version                      = var.opencti_version
  opencti_worker_service_desired_count = var.opencti_worker_service_desired_count
  opencti_worker_service_max_count     = var.opencti_worker_service_max_count
  opencti_worker_service_min_count     = var.opencti_worker_service_min_count
  opencti_worker_memory_size           = var.opencti_worker_memory_size
  opencti_worker_cpu_size              = var.opencti_worker_cpu_size
}


module "rabbitmq" {
  source                                             = "./rabbitmq"
  resource_prefix                                    = var.resource_prefix
  ecs_cluster                                        = aws_ecs_cluster.this.id
  vpc_id                                             = var.vpc_id
  log_retention                                      = var.log_retention
  private_subnet_ids                                 = var.private_subnet_ids
  private_cidr_blocks                                = var.private_cidr_blocks
  enable_ecs_exec                                    = var.enable_ecs_exec
  rabbitmq_image_tag                                 = var.rabbitmq_image_tag
  rabbitmq_cluster_load_balancer_target_group_arn    = var.rabbitmq_cluster_load_balancer_target_group_arn
  rabbitmq_management_load_balancer_target_group_arn = var.rabbitmq_management_load_balancer_target_group_arn
  rabbitmq_node_port                                 = var.rabbitmq_node_port
  rabbitmq_management_port                           = var.rabbitmq_management_port
  rabbitmq_cpu_size                                  = var.rabbitmq_cpu_size
  rabbitmq_memory_size                               = var.rabbitmq_memory_size
  secrets_manager_recovery_window                    = var.secrets_manager_recovery_window
  private_network_load_balancer_static_ips           = var.private_network_load_balancer_static_ips
  private_network_load_balancer_dns                  = var.private_network_load_balancer_dns
}