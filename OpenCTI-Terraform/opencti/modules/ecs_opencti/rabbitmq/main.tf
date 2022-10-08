###########################
# -- RabbitMQ Task Def -- #
###########################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.resource_prefix}-rabbitmq-task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.rabbitmq_execution.arn
  task_role_arn            = aws_iam_role.rabbitmq_task.arn
  cpu                      = var.rabbitmq_cpu_size
  memory                   = var.rabbitmq_memory_size
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      "name" : "rabbitmq",
      "image" : "rabbitmq:${var.rabbitmq_image_tag}",
      "cpu" : var.rabbitmq_cpu_size, # Allowing Container to use all of Fargate's resources
      "memory" : var.rabbitmq_memory_size,
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.this.name}",
          "awslogs-region" : "${data.aws_region.current.name}",
          "awslogs-create-group" : "true",
          "awslogs-stream-prefix" : "${var.resource_prefix}"
        }
      },
      "portMappings" : [
        {
          "containerPort" : var.rabbitmq_node_port,
          "hostPort" : var.rabbitmq_node_port
        },
        {
          "containerPort" : var.rabbitmq_management_port,
          "hostPort" : var.rabbitmq_management_port
        }
      ],
      "secrets" : [
        {
          "name" : "RABBITMQ_DEFAULT_USER",
          "valueFrom" : "${aws_secretsmanager_secret_version.this.arn}:username::"
        },
        {
          "name" : "RABBITMQ_DEFAULT_PASS",
          "valueFrom" : "${aws_secretsmanager_secret_version.this.arn}:password::"
        }
      ],
      "environment" : [
        {
          "name" : "RABBITMQ_NODE_PORT",
          "value" : "${tostring(var.rabbitmq_node_port)}"
        },
        {
          "name" : "RABBITMQ_NODENAME",
          "value" : "rabbitmq@localhost" # localhost is important to ensure no platform issues if the Fargate instance fails
        }
      ],
      "mountPoints" : [
        {
          "containerPath" : "/var/lib/rabbitmq",
          "sourceVolume" : "rabbitmq_efs"
        }
      ]
  }])
  volume {
    name = "rabbitmq_efs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"
    }
  }
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}
resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/rabbitmq"
  retention_in_days = var.log_retention
}


#############################
# -- RabbitMQ EFS Volume -- #
#############################
resource "aws_efs_file_system" "this" {
  creation_token   = "${var.resource_prefix}-rabbitmq-efs"
  performance_mode = "maxIO"
  encrypted        = true
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.inbound_efs.id]
}

resource "aws_security_group" "inbound_efs" {
  name        = "${var.resource_prefix}-rabbitmq-efs-security-group"
  description = "RabbitMQ EFS"
  vpc_id      = var.vpc_id
  ingress {
    description     = "RabbitMQ EFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "TCP"
    security_groups = [aws_security_group.rabbitmq.id]
  }
}

##############################
# -- RabbitMQ Credentials -- #
##############################
resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.resource_prefix}-platform-rabbitmq-credentials"
  description             = "RabbitMQ username and password for OpenCTI node access."
  recovery_window_in_days = var.secrets_manager_recovery_window
}

resource "random_password" "this" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = <<EOF
  {
    "username": "rabbitmq-opencti",
    "password": "${random_password.this.result}"
  }
  EOF
}


#####################################
# -- RabbitMQ IAM Execution Role -- #
#####################################

resource "aws_iam_role" "rabbitmq_execution" {
  name               = "${var.resource_prefix}-rabbitmq-execution-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "rabbitmq_execution" {
  role       = aws_iam_role.rabbitmq_execution.name
  policy_arn = aws_iam_policy.rabbitmq_execution.arn
}

resource "aws_iam_policy" "rabbitmq_execution" {
  name = "${var.resource_prefix}-rabbitmq-execution-policy"
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
          "${aws_secretsmanager_secret.this.arn}"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

##############################
# -- RabbitMQ IAM Task Role -- #
##############################
resource "aws_iam_role" "rabbitmq_task" {
  name               = "${var.resource_prefix}-rabbitmq-task-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "rabbitmq_task" {
  role       = aws_iam_role.rabbitmq_task.name
  policy_arn = aws_iam_policy.rabbitmq_task.arn
}

resource "aws_iam_policy" "rabbitmq_task" {
  name = "${var.resource_prefix}-rabbitmq-task-policy"
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
      }
    ]
  })
}

##############################
# -- ECS RabbitMQ Service -- #
##############################

resource "aws_ecs_service" "this" {
  name                              = "${var.resource_prefix}-rabbitmq-service"
  cluster                           = var.ecs_cluster
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60
  enable_execute_command            = var.enable_ecs_exec
  force_new_deployment              = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.rabbitmq.id]
  }
  load_balancer {
    target_group_arn = var.rabbitmq_cluster_load_balancer_target_group_arn
    container_port   = var.rabbitmq_node_port
    container_name   = "rabbitmq"
  }
  load_balancer {
    target_group_arn = var.rabbitmq_management_load_balancer_target_group_arn
    container_port   = var.rabbitmq_management_port
    container_name   = "rabbitmq"
  }
}

resource "aws_security_group" "rabbitmq" {
  name        = "${var.resource_prefix}-rabbitmq-security-group"
  description = "RabbitMQ Access"
  vpc_id      = var.vpc_id
  ingress {
    description = "RabbitMQ Management UI"
    from_port   = var.rabbitmq_management_port
    to_port     = var.rabbitmq_management_port
    protocol    = "TCP"
    cidr_blocks = formatlist("%s/32", var.private_network_load_balancer_static_ips)
  }
  ingress {
    description = "RabbitMQ API"
    from_port   = var.rabbitmq_node_port
    to_port     = var.rabbitmq_node_port
    protocol    = "TCP"
    cidr_blocks = formatlist("%s/32", var.private_network_load_balancer_static_ips)
  }
  egress {
    description = "Access to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###########################
# --  RabbitMQ Metrics -- #
###########################
# EventBridge
resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.resource_prefix}-rabbitmq-metric-collection"
  schedule_expression = "cron(0/5 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.id
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "./resources/lambda/rabbitmq_metrics"
  output_path = "./resources/lambda/rabbitmq_metrics.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = "${var.resource_prefix}-rabbitmq-metrics"
  handler          = "rabbitmq_metrics.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = aws_iam_role.lambda.arn
  timeout          = 900
  architectures    = ["arm64"]
  #checkov:skip=CKV_AWS_115:Concurrency Limits are not required for this Lambda function.
  #checkov:skip=CKV_AWS_116:Dead Letter Queues are not required for this Lambda function.
  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.rabbitmq_lambda.id]
  }
  environment {
    variables = {
      LOG_LEVEL            = "INFO"
      SECRETS_ARN          = "${aws_secretsmanager_secret_version.this.arn}"
      RABBITMQ_ENDPOINT    = "http://${var.private_network_load_balancer_dns}:${var.rabbitmq_management_port}"
      RABBITMQ_METRIC_NAME = "${var.rabbitmq_queue_metric_name}"
      RABBITMQ_NAMESPACE   = "${var.rabbitmq_metric_namespace}"
    }
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_security_group" "rabbitmq_lambda" {
  name        = "${var.resource_prefix}-rabbitmq-lambda-sg"
  description = "RabbitMQ Lambda"
  vpc_id      = var.vpc_id
}

# Can be locked down further
resource "aws_security_group_rule" "access_secrets_manager" {
  description       = "Access to Secrets Manager and other resources"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rabbitmq_lambda.id
  cidr_blocks       = ["0.0.0.0/0"]
}

################################
# -- Lambda Resource Policy -- #
################################
resource "aws_lambda_permission" "this" {
  statement_id  = "${var.resource_prefix}-eventbridge-rabbitmq-exec"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/${var.resource_prefix}-*"
}

#########################
# -- Lambda IAM Role -- #
#########################

resource "aws_iam_role" "lambda" {
  name               = "${var.resource_prefix}-lambda-rabbitmq-metrics-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.resource_prefix}-lambda-rabbitmq-metrics-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  #checkov:skip=CKV_AWS_111:Write constraints are added where possible. It is not possible to restrict the Network Interfaces section.
  statement {
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"

      values = [
        "${var.rabbitmq_metric_namespace}"
      ]
    }
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "${aws_secretsmanager_secret.this.arn}"
    ]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "ArnLikeIfExists"
      variable = "ec2:Vpc"

      values = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/${var.vpc_id}"
      ]
    }
  }
}
