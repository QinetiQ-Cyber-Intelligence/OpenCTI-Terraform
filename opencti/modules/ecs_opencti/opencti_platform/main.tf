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
      "environment" : [
        {
          "name" : "APP__PORT",
          "value" : "${tostring(var.opencti_platform_port)}"
        },
        {
          "name" : "APP__ADMIN__EMAIL",
          "value" : "${var.opencti_platform_admin_email}"
        },
        {
          "name" : "NODE_OPTIONS",
          "value" : "--max-old-space-size=${tostring(var.opencti_platform_memory_size)}"
        },
        {
          "name" : "APP__APP_LOGS__LOGS_LEVEL",
          "value" : "${var.opencti_logging_level}"
        },
        {
          "name" : "REDIS__HOSTNAME",
          "value" : "${var.elasticache_endpoint_address}"
        },
        {
          "name" : "REDIS__PORT",
          "value" : "${var.elasticache_redis_port}"
        },
        {
          "name" : "REDIS__USE_SSL",
          "value" : "true"
        },
        {
          "name" : "REDIS__TRIMMING",
          "value" : "${tostring(var.redis_trimming)}"
        },
        {
          "name" : "ELASTICSEARCH__URL",
          "value" : "https://${var.opensearch_endpoint_address}"
        },
        {
          "name" : "ELASTICSEARCH__NUMBER_OF_SHARDS",
          "value" : "${tostring(var.opensearch_template_primary_shard_count)}"
        },
        {
          "name" : "MINIO__ENDPOINT",
          "value" : "s3.${data.aws_region.current.name}.amazonaws.com"
        },
        {
          "name" : "MINIO__PORT",
          "value" : "443"
        },
        {
          "name" : "MINIO__BUCKET_NAME",
          "value" : "${var.minio_s3_bucket_name}"
        },
        {
          "name" : "MINIO__BUCKET_REGION",
          "value" : "${data.aws_region.current.name}"
        },
        {
          "name" : "MINIO__USE_SSL",
          "value" : "true"
        },
        {
          "name" : "MINIO__USE_AWS_ROLE",
          "value" : "true"
        },
        {
          "name" : "RABBITMQ__HOSTNAME",
          "value" : "${var.private_network_load_balancer_dns}"
        },
        {
          "name" : "RABBITMQ__PORT",
          "value" : "${tostring(var.rabbitmq_node_port)}"
        },
        {
          "name" : "RABBITMQ__PORT_MANAGEMENT",
          "value" : "${tostring(var.rabbitmq_management_port)}"
        },
        {
          "name" : "RABBITMQ__USE_SSL",
          "value" : "false"
        }
      ]
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

# OpenID Connect configuration information. If OpenID Connect is used, these should be added to the above `environment` section of ECS OpenCTI Platform.
# {
#   "name" : "PROVIDERS__OPENID__STRATEGY",
#   "value" : "OpenIDConnectStrategy"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__LABEL",
#   "value" : "IdP Authentication"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__ISSUER",
#   "value" : "${var.oidc_information.issuer}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__CLIENT_ID",
#   "value" : "${var.oidc_information.client_id}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__CLIENT_SECRET",
#   "value" : "${var.oidc_information.client_secret}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__REDIRECT_URIS",
#   "value" : "${var.oidc_information.redirect_uris}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__TOKEN_REFERENCE",
#   "value" : "${var.opencti_openid_mapping_config.chosen_token}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_SCOPE",
#   "value" : "${var.opencti_openid_mapping_config.requested_scopes}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_MAPPING",
#   "value" : "${var.opencti_openid_mapping_config.opencti_roles_mapping}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_PATH",
#   "value" : "${var.opencti_openid_mapping_config.oidc_group_claim_path}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__TOKEN_REFERENCE",
#   "value" : "${var.opencti_openid_mapping_config.chosen_token}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_SCOPE",
#   "value" : "${var.opencti_openid_mapping_config.requested_scopes}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_MAPPING",
#   "value" : "${var.opencti_openid_mapping_config.opencti_groups_mapping}"
# },
# {
#   "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_PATH",
#   "value" : "${var.opencti_openid_mapping_config.oidc_group_claim_path}"
# },
# {
#   "name" : "PROVIDERS__LOCAL__STRATEGY",
#   "value" : "LocalStrategy"
# }

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/opencti-platform"
  retention_in_days = var.log_retention
  kms_key_id        = var.kms_key_arn
}


##########################################
# -- OpenCTI Platform Master Password -- #
##########################################
resource "aws_secretsmanager_secret" "master_password" {
  name                    = "${var.resource_prefix}-infrastructure-opencti-master-user-credentials"
  description             = "Master User credentials for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
  kms_key_id              = var.kms_key_arn
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
  name                    = "${var.resource_prefix}-infrastructure-opencti-master-user-apikey"
  description             = "Master API Key for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
  kms_key_id              = var.kms_key_arn
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
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = [
          "${var.kms_key_arn}"
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}-infrastructure*",
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
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = ["${var.kms_key_arn}"]
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
