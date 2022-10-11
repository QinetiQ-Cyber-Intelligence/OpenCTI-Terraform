####################################
# -- OpenCTI Connector Task Def -- #
####################################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
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
      "secrets" : module.secrets.secrets_list,
      "environment" : jsondecode(templatefile(
        var.environment_variable_template,
        {
          OPENCTI_PLATFORM_URL = var.opencti_platform_url,
          RANDOM_UUID          = random_uuid.this.id
        }
      ))
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/opencti-${var.container_name}"
  retention_in_days = var.log_retention
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
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}-connector-${var.container_name}*",
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
  desired_count        = 0
  launch_type          = "FARGATE"
  force_new_deployment = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.connector_security_group_id]
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

###################################
# --    Create User Account    -- # 
###################################

# Retrieve the existing master user credentials
# These are used when creating the connector's user account
data "aws_secretsmanager_secret" "master_creds" {
  name = "${var.resource_prefix}-platform-opencti-master-user-credentials"
}

data "aws_secretsmanager_secret_version" "master_creds" {
  secret_id = data.aws_secretsmanager_secret.master_creds.id
}

# Generate a random password for the connector's user account
resource "random_password" "connector_account_password" {
  length           = 16
  special          = true
}

# Execute python script to create the connector's user account
# Use the output API token as a replacement for the secret template file
data "external" "create_account" {
  program = ["python3", "${path.root}/resources/create_user_account.py"]
  query = {
    opencti_url    = var.opencti_url
    admin_email    = jsondecode(data.aws_secretsmanager_secret_version.master_creds.secret_string).username
    admin_password = jsondecode(data.aws_secretsmanager_secret_version.master_creds.secret_string).password
    name           = var.container_name
    email          = "${var.container_name}@${var.email_domain}"
    password       = "${random_password.connector_account_password.result}"
    first_name     = var.container_name
    last_name      = var.container_name
    description    = "User account for the connector \"${var.container_name}\"."
  }
}

# Create the secrets and use output variable secrets_list in the task definition
module "secrets" {
  source      = "../../secrets-terraform-module"
  secret_name = "${var.resource_prefix}-${var.container_name}-connector"
  secrets_manager_recovery_window = var.secrets_manager_recovery_window
  # If no secret template was provided, only created the OPENCTI_TOKEN secret,
  # otherwise use the template provided.
  secrets_map = (var.secrets_template == "") ? {"OPENCTI_TOKEN": data.external.create_account.result["api_token"]} : jsondecode(templatefile(
    var.secrets_template,
    {
      OPENCTI_TOKEN = data.external.create_account.result["api_token"]
    }
  ))
}

# If secrets have changed, force a new deployment of the ECS service
resource "null_resource" "force_deployment" {
  triggers = {
    version_id = module.secrets.version_id
  }
  provisioner "local-exec" {
    command = "aws ecs update-service --cluster ${var.ecs_cluster} --service ${aws_ecs_service.this.name} --force-new-deployment --region ${data.aws_region.current.name}"
  }
}

###############################
# -- EventBridge Scheduler -- #
###############################
resource "aws_cloudwatch_event_rule" "start_container" {
  name                = "${var.resource_prefix}-${var.container_name}-start"
  schedule_expression = var.eventbridge_cron.start
}


resource "aws_cloudwatch_event_target" "start_container" {
  arn   = var.halt_connector_lambda_arn
  rule  = aws_cloudwatch_event_rule.start_container.id
  input = <<EOF
{
  "service_target": "${aws_ecs_service.this.name}",
  "action": "start",
  "cluster": "${var.ecs_cluster}"
}
EOF
}

resource "aws_cloudwatch_event_rule" "stop_container" {
  name                = "${var.resource_prefix}-${var.container_name}-stop"
  schedule_expression = var.eventbridge_cron.stop
}

resource "aws_cloudwatch_event_target" "stop_container" {
  arn   = var.halt_connector_lambda_arn
  rule  = aws_cloudwatch_event_rule.stop_container.id
  input = <<EOF
{
  "service_target": "${aws_ecs_service.this.name}",
  "action": "stop",
  "cluster": "${var.ecs_cluster}"
}
EOF
}
