locals {
  environment_variables = jsondecode(templatefile(
    (var.oidc_information.client_id == "") ? "./resources/container_env_definitions/opencti_platform.hcl" : "./resources/container_env_definitions/opencti_platform_oidc.hcl",
    {
      opencti_platform_port                   = tostring(var.opencti_platform_port)
      opencti_platform_admin_email            = var.opencti_platform_admin_email
      opencti_platform_memory_size            = tostring(var.opencti_platform_memory_size)
      opencti_logging_level                   = var.opencti_logging_level
      elasticache_endpoint_address            = var.elasticache_endpoint_address
      elasticache_redis_port                  = var.elasticache_redis_port
      redis_trimming                          = tostring(var.redis_trimming)
      opensearch_endpoint_address             = var.opensearch_endpoint_address
      opensearch_template_primary_shard_count = tostring(var.opensearch_template_primary_shard_count)
      aws_region                              = data.aws_region.current.name
      minio_s3_bucket_name                    = var.minio_s3_bucket_name
      private_network_load_balancer_dns       = var.private_network_load_balancer_dns
      rabbitmq_node_port                      = tostring(var.rabbitmq_node_port)
      rabbitmq_management_port                = tostring(var.rabbitmq_management_port)
      oidc_information_issuer                 = var.oidc_information.issuer
      oidc_information_client_id              = var.oidc_information.client_id
      oidc_information_client_secret          = var.oidc_information.client_secret
      oidc_information_redirect_uris          = jsonencode(jsonencode(var.oidc_information.redirect_uris))
      opencti_openid_mapping_config_groups_token   = var.opencti_openid_mapping_config.groups_token
      opencti_openid_mapping_config_groups_scope   = var.opencti_openid_mapping_config.groups_scope
      opencti_openid_mapping_config_groups_path    = jsonencode(jsonencode(var.opencti_openid_mapping_config.groups_path))
      opencti_openid_mapping_config_groups_mapping = jsonencode(jsonencode(var.opencti_openid_mapping_config.groups_mapping))
      opencti_openid_mapping_config_roles_token    = var.opencti_openid_mapping_config.roles_token
      opencti_openid_mapping_config_roles_scope    = var.opencti_openid_mapping_config.roles_scope
      opencti_openid_mapping_config_roles_path     = jsonencode(jsonencode(var.opencti_openid_mapping_config.roles_path))
      opencti_openid_mapping_config_roles_mapping  = jsonencode(jsonencode(var.opencti_openid_mapping_config.roles_mapping))
  }))
}

###################################
# -- OpenCTI Platform Task Def -- #
###################################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Defining the Container Image and Container role
resource "aws_ecs_task_definition" "opencti-platform" {
  family                   = "${var.resource_prefix}-opencti-platform-task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.opencti_platform_execution.arn
  task_role_arn            = aws_iam_role.opencti_platform_task.arn
  cpu                      = var.opencti_platform_cpu_size
  memory                   = var.opencti_platform_memory_size
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      "name" : "opencti-platform",
      "image" : "opencti/platform:${var.opencti_version}",
      "cpu" : var.opencti_platform_cpu_size,
      "memory" : var.opencti_platform_memory_size,
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.this.name}",
          "awslogs-region" : "${data.aws_region.current.name}",
          "awslogs-create-group" : "true",
          "awslogs-stream-prefix" : "opencti-platform"
        }
      },
      "portMappings" : [
        {
          "containerPort" : var.opencti_platform_port,
          "hostPort" : var.opencti_platform_port
        }
      ],
      "secrets" : [
        {
          "name" : "APP__ADMIN__PASSWORD",
          "valueFrom" : "${aws_secretsmanager_secret_version.master_password.arn}:password::"
        },
        {
          "name" : "APP__ADMIN__TOKEN",
          "valueFrom" : "${aws_secretsmanager_secret_version.master_api_key.arn}:apikey::"
        },
        {
          "name" : "ELASTICSEARCH__USERNAME",
          "valueFrom" : "${var.opensearch_credentials_arn}:username::"
        },
        {
          "name" : "ELASTICSEARCH__PASSWORD",
          "valueFrom" : "${var.opensearch_credentials_arn}:password::"
        },
        {
          "name" : "RABBITMQ__USERNAME",
          "valueFrom" : "${var.rabbitmq_credentials_arn}:username::"
        },
        {
          "name" : "RABBITMQ__PASSWORD",
          "valueFrom" : "${var.rabbitmq_credentials_arn}:password::"
        },
        {
          "name" : "REDIS__USERNAME",
          "valueFrom" : "${var.elasticache_credentials_arn}:username::"
        },
        {
          "name" : "REDIS__PASSWORD",
          "valueFrom" : "${var.elasticache_credentials_arn}:password::"
        }
      ],
      "environment" : local.environment_variables
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/opencti-platform"
  retention_in_days = var.log_retention
}


##########################################
# -- OpenCTI Platform Master Password -- #
##########################################
resource "aws_secretsmanager_secret" "master_password" {
  name                    = "${var.resource_prefix}-platform-opencti-master-user-credentials"
  description             = "Master User credentials for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
}

resource "random_password" "master_password" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret_version" "master_password" {
  secret_id     = aws_secretsmanager_secret.master_password.id
  secret_string = <<EOF
  {
    "username": "${var.opencti_platform_admin_email}",
    "password": "${random_password.master_password.result}"
  }
  EOF
}

##################################
# -- OpenCTI Platform API Key -- #
##################################

resource "random_uuid" "opencti_platform_uuidv4_token" {}

resource "aws_secretsmanager_secret" "master_api_key" {
  name                    = "${var.resource_prefix}-platform-opencti-master-user-apikey"
  description             = "Master API Key for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
}

resource "random_password" "master_api_key" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret_version" "master_api_key" {
  secret_id     = aws_secretsmanager_secret.master_api_key.id
  secret_string = <<EOF
  {
    "apikey": "${random_uuid.opencti_platform_uuidv4_token.id}"
  }
  EOF
}

#####################################
# -- Platform IAM Execution Role -- #
#####################################

resource "aws_iam_role" "opencti_platform_execution" {
  name               = "${var.resource_prefix}-platform-execution-role"
  assume_role_policy = data.aws_iam_policy_document.opencti_platform_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "opencti_platform_execution" {
  role       = aws_iam_role.opencti_platform_execution.name
  policy_arn = aws_iam_policy.opencti_platform_execution.arn
}

resource "aws_iam_policy" "opencti_platform_execution" {
  name = "${var.resource_prefix}-platform-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
        Effect   = "Allow"
        Resource = ["${aws_cloudwatch_log_group.this.arn}:*"]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}-platform*",
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "opencti_platform_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

################################
# -- Platform IAM Task Role -- #
################################
resource "aws_iam_role" "opencti_platform_task" {
  name               = "${var.resource_prefix}-platform-task-role"
  assume_role_policy = data.aws_iam_policy_document.opencti_platform_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "opencti_platform_task" {
  role       = aws_iam_role.opencti_platform_task.name
  policy_arn = aws_iam_policy.opencti_platform_task.arn
}

resource "aws_iam_policy" "opencti_platform_task" {
  name = "${var.resource_prefix}-platform-task-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "${var.minio_s3_bucket_arn}",
          "${var.minio_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

#####################################
# -- ECS Public Platform Service -- #
#####################################

resource "aws_ecs_service" "public" {
  name                   = "${var.resource_prefix}-platform-public-service"
  cluster                = var.ecs_cluster
  task_definition        = aws_ecs_task_definition.opencti-platform.arn
  desired_count          = var.opencti_platform_service_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_ecs_exec
  force_new_deployment   = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.this.id]
  }
  health_check_grace_period_seconds = 60
  load_balancer {
    target_group_arn = var.public_load_balancer_target_group_arn
    container_name   = "opencti-platform"
    container_port   = var.opencti_platform_port
  }
}


######################################
# -- ECS Private Platform Service -- #
######################################

resource "aws_ecs_service" "private" {
  name                   = "${var.resource_prefix}-platform-private-service"
  cluster                = var.ecs_cluster
  task_definition        = aws_ecs_task_definition.opencti-platform.arn
  desired_count          = var.opencti_platform_service_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_ecs_exec
  force_new_deployment   = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.this.id]
  }
  health_check_grace_period_seconds = 60
  load_balancer {
    target_group_arn = var.opencti_platform_load_balancer_target_group_arn
    container_name   = "opencti-platform"
    container_port   = var.opencti_platform_port
  }
  # Enables autoscaling changes to remain on future deployments
  lifecycle {
    ignore_changes = [desired_count]
  }
}

##############################
# -- AutoScaling Platform -- #
##############################
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.opencti_platform_service_max_count
  min_capacity       = var.opencti_platform_service_min_count
  resource_id        = "service/${var.resource_prefix}-cluster/${aws_ecs_service.private.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

##########################
# -- SG Configuration -- #
##########################
resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-opencti-platform-sg"
  description = "OpenCTI Platform Access"
  vpc_id      = var.vpc_id
}

# Separate rules are required to avoid a cyclic error
resource "aws_security_group_rule" "inbound_alb" {
  description              = "OpenCTI Platform Application Load Balancer"
  type                     = "ingress"
  from_port                = var.opencti_platform_port
  to_port                  = var.opencti_platform_port
  protocol                 = "TCP"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.application_load_balancer_security_group
}

resource "aws_security_group_rule" "inbound_nlb" {
  description       = "OpenCTI Platform Network Load Balancer"
  type              = "ingress"
  from_port         = var.opencti_platform_port
  to_port           = var.opencti_platform_port
  protocol          = "TCP"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = formatlist("%s/32", var.private_network_load_balancer_static_ips)
}

resource "aws_security_group_rule" "egress" {
  description       = "Access to internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}
