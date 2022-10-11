###################################
# -- OpenCTI Worker Task Def -- #
###################################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
# Defining the Container Image and Container role
resource "aws_ecs_task_definition" "opencti_worker" {
  family                   = "${var.resource_prefix}-opencti-worker-task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.opencti_worker_execution.arn
  task_role_arn            = aws_iam_role.opencti_worker_task.arn
  cpu                      = var.opencti_worker_cpu_size
  memory                   = var.opencti_worker_memory_size
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      "name" : "opencti-worker",
      "image" : "opencti/worker:${var.opencti_version}",
      "cpu" : var.opencti_worker_cpu_size, # Allowing Container to use all of Fargate's resources
      "memory" : var.opencti_worker_memory_size,
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.this.name}"
          "awslogs-region" : "${data.aws_region.current.name}",
          "awslogs-create-group" : "true",
          "awslogs-stream-prefix" : "${var.resource_prefix}"
        }
      },
      "secrets" : [
        {
          "name" : "OPENCTI_TOKEN",
          "valueFrom" : "${var.opencti_platform_token}:apikey::"
        }
      ],
      "environment" : [
        {
          "name" : "OPENCTI_URL",
          "value" : "${var.opencti_platform_url}"
        },
        {
          "name" : "WORKER_LOG_LEVEL",
          "value" : "${var.opencti_logging_level}"
        }
      ]
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/ecs/opencti-worker"
  retention_in_days = var.log_retention
}


###################################
# -- Worker IAM Execution Role -- #
###################################

resource "aws_iam_role" "opencti_worker_execution" {
  name               = "${var.resource_prefix}-worker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.opencti_worker_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "opencti_worker_execution" {
  role       = aws_iam_role.opencti_worker_execution.name
  policy_arn = aws_iam_policy.opencti_worker_execution.arn
}

resource "aws_iam_policy" "opencti_worker_execution" {
  name = "${var.resource_prefix}-worker-execution-policy"
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
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}-platform-opencti-master-user-apikey*",
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "opencti_worker_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

##############################
# -- Worker IAM Task Role -- #
##############################
resource "aws_iam_role" "opencti_worker_task" {
  name               = "${var.resource_prefix}-worker-task-role"
  assume_role_policy = data.aws_iam_policy_document.opencti_worker_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "opencti_worker_task" {
  role       = aws_iam_role.opencti_worker_task.name
  policy_arn = aws_iam_policy.opencti_worker_task.arn
}

resource "aws_iam_policy" "opencti_worker_task" {
  name = "${var.resource_prefix}-worker-task-policy"
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


############################
# -- ECS Worker Service -- #
############################

resource "aws_ecs_service" "this" {
  name                               = "${var.resource_prefix}-worker-service"
  cluster                            = var.ecs_cluster
  task_definition                    = aws_ecs_task_definition.opencti_worker.arn
  desired_count                      = var.opencti_worker_service_desired_count
  launch_type                        = "FARGATE"
  enable_execute_command             = var.enable_ecs_exec
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.this.id]
  }
  # Enables autoscaling changes to remain on future deployments
  lifecycle {
    ignore_changes = [desired_count]
  }
}

############################
# -- AutoScaling Worker -- #
############################
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.opencti_worker_service_max_count
  min_capacity       = var.opencti_worker_service_min_count
  resource_id        = "service/${var.resource_prefix}-cluster/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#########################
# -- Worker Scale Up -- #
#########################
resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name        = "${var.resource_prefix}-worker-scale-up"
  alarm_description = "Alerting when the number of RabbitMQ messages to process is greater than or equal to 1000."
  # If the number of messages is greater or equal to 1000
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1000
  statistic           = "Maximum"
  evaluation_periods  = "1"
  metric_name         = var.rabbitmq_queue_metric_name
  namespace           = var.rabbitmq_metric_namespace
  period              = "300"
  alarm_actions       = [aws_appautoscaling_policy.scale_up_policy.arn]
}

resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "${var.resource_prefix}-worker-scale-up-policy"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 300
    metric_aggregation_type = "Maximum"
    # Step adjustment lower and upper bound defines the upper and lower boundaries that 
    # are applied to the CloudWatch Alarm Threshold
    # If Threshold is 1000 and LB = -20 and UB = 20, then the scaling adjustment
    # configured will occur when the metric is between 980 and 1020.
    step_adjustment {
      scaling_adjustment          = var.opencti_worker_service_max_count
      metric_interval_lower_bound = 0
    }
  }
}

###########################
# -- Worker Scale Down -- #
###########################
resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name        = "${var.resource_prefix}-worker-scale-down"
  alarm_description = "Alerting when the number of RabbitMQ messages to process is less than 1000."
  # If the number of messages is less than than 1000
  comparison_operator = "LessThanThreshold"
  threshold           = 1000
  statistic           = "Maximum"
  evaluation_periods  = "1"
  metric_name         = var.rabbitmq_queue_metric_name
  namespace           = var.rabbitmq_metric_namespace
  period              = "300"
  alarm_actions       = [aws_appautoscaling_policy.scale_down_policy.arn]
}

resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "${var.resource_prefix}-worker-scale-down-policy"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 300
    metric_aggregation_type = "Maximum"
    step_adjustment {
      scaling_adjustment          = var.opencti_worker_service_min_count
      metric_interval_lower_bound = 0
    }
  }
}

##########################
# -- SG Configuration -- #
##########################
resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-opencti-worker-sg"
  description = "OpenCTI Workers"
  vpc_id      = var.vpc_id
  egress {
    description = "Access to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}