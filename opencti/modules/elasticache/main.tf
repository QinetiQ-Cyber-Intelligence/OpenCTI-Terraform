###########################
# -- Redis ElastiCache -- #
###########################
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.resource_prefix}-redis-group"
  description          = "Multi-AZ Redis deployment for OpenCTI."

  multi_az_enabled           = true
  automatic_failover_enabled = true

  num_node_groups         = var.elasticache_node_groups_count
  replicas_per_node_group = var.elasticache_replication_count

  node_type                  = var.elasticache_instance_type
  port                       = var.elasticache_redis_port
  security_group_ids         = [aws_security_group.this.id]
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  engine                     = "redis"
  engine_version             = var.elasticache_redis_version
  parameter_group_name       = var.elasticache_parameter_group_name
  maintenance_window         = var.elasticache_redis_maintenance_period
  auto_minor_version_upgrade = true
  apply_immediately          = true
  #checkov:skip=CKV_AWS_31:OpenCTI Platform does not support 'auth_token', instead username/password is used.
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  user_group_ids             = [aws_elasticache_user_group.this.id]
  snapshot_retention_limit   = var.elasticache_redis_snapshot_retention_limit
  snapshot_window            = var.elasticache_redis_snapshot_time
  depends_on = [
    aws_elasticache_user_group_association.this
  ]
}

resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-elasticache"
  vpc_id      = var.vpc_id
  description = "Redis Access"
  ingress {
    description     = "Redis API"
    from_port       = var.elasticache_redis_port
    to_port         = var.elasticache_redis_port
    protocol        = "tcp"
    security_groups = var.accepted_security_group_ids
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.resource_prefix}-multi-az-target"
  subnet_ids = var.private_subnet_ids
}

#########################################
# -- ElastiCache Original User Group -- #
#########################################

##################################
# -- ElastiCache OpenCTI User -- #
##################################
resource "aws_elasticache_user_group" "this" {
  engine        = "REDIS"
  user_group_id = "openctiusergroup"
  user_ids = [
    aws_elasticache_user.default.id
  ]
  lifecycle {
    ignore_changes = [user_ids]
  }
}

resource "aws_elasticache_user_group_association" "this" {
  user_group_id = aws_elasticache_user_group.this.id
  user_id       = aws_elasticache_user.this.id
}
resource "aws_elasticache_user" "this" {
  user_id       = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["username"]
  user_name     = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["username"]
  access_string = "on ~* +@all" # Unrestricted access
  engine        = "REDIS"
  passwords     = [jsondecode(aws_secretsmanager_secret_version.this.secret_string)["password"]]
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.resource_prefix}-infrastructure-elasticache-credentials"
  description             = "Elasticache password for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
  kms_key_id              = var.kms_key_arn
}

resource "random_password" "elasticache_password" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = <<EOF
  {
    "username": "elasticaheopenctiaccess",
    "password": "${random_password.elasticache_password.result}"
  }
  EOF
}

##################################
# -- ElastiCache Default User -- #
##################################

# Default User
# As RBAC is new to Redis, it requires a default user to be present on any user groups.
# This may change in the future but for now we create a default user with no permissions.
# https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html#Access-string:~:text=ElastiCache%20automatically%20configures,modified%20access%20string.
resource "aws_elasticache_user" "default" {
  user_id       = "defaultuserid"
  user_name     = "default"
  access_string = "off &* -@all"
  engine        = "REDIS"
  passwords     = [random_password.default_password.result]
}

resource "random_password" "default_password" {
  length  = 32
  special = false
}