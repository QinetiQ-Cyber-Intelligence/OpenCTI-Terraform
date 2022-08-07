####################################
# -- OpenCTI Connector Task Def -- #
####################################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_secretsmanager_secret" "this" {
  name = "${var.resource_prefix}-connector-${var.container_name}"
}
resource "random_uuid" "this" {}

# Defining the Container Image and Container role
resource "aws_ecs_task_definition" "opencti_connnector" {
  family                   = "${var.resource_prefix}-${var.container_name}"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.this.arn
  cpu                      = var.opencti_connector_cpu_size
  memory                   = var.opencti_connector_memory_size
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      "name" : "${var.resource_prefix}-${var.container_name}",
      "image" : "${var.opencti_connector_image}:${var.opencti_version}",
      "cpu" : var.opencti_connector_cpu_size,
      "memory" : var.opencti_connector_memory_size,
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
      "secrets" : [
        {
          "name" : "OPENCTI_TOKEN",
          "valueFrom" : "${data.aws_secretsmanager_secret.this.arn}:apikey::"
        }
      ],
      "environment" : var.environment_variable_def
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/opencti-${var.container_name}"
  retention_in_days = var.log_retention
  kms_key_id        = var.opencti_connector_kms_arn
}

######################################
# -- Connector IAM Execution Role -- # 
######################################
resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-${var.container_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_policy" "this" {
  name = "${var.resource_prefix}-${var.container_name}-execution-policy"
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
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}-connector-${var.container_name}*"
        ]
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = [
          "${var.opencti_connector_kms_arn}"
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

###############################
# -- ECS Connector Service -- # 
###############################

resource "aws_ecs_service" "this" {
  name                 = "${var.resource_prefix}-${var.container_name}-service"
  cluster              = var.ecs_cluster
  task_definition      = aws_ecs_task_definition.opencti_connnector.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.connector_security_group_id]
  }
}