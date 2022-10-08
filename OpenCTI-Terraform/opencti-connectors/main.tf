############################
# -- Required Resources -- #
############################
resource "aws_ecs_cluster" "this" {
  name = "${var.resource_prefix}-connectors-cluster"

  configuration {
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

#### CloudWatch Cluster Logging ####
resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}-connectors-cluster"
  retention_in_days = var.log_retention
}

#### Networking ####
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.resource_prefix}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${var.resource_prefix}-private-*"]
  }
}

resource "aws_security_group" "opencti_connector" {
  #checkov:skip=CKV2_AWS_5:This is a placeholder Security Group, used by the OpenCTI Connector deployment.
  name        = "${var.resource_prefix}-opencti-connector-sg"
  description = "OpenCTI Connectors"
  vpc_id      = data.aws_vpc.this.id
  egress {
    description = "Access to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "lambda" {
  source          = "./modules/lambda"
  resource_prefix = var.resource_prefix
  cluster_name    = aws_ecs_cluster.this.name
}
