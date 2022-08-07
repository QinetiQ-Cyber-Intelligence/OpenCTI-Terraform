############################
# -- Required Resources -- #
############################
resource "aws_ecs_cluster" "this" {
  name = "${var.resource_prefix}-connectors-cluster"

  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"
      kms_key_id = var.opencti_connector_kms_arn
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
  kms_key_id        = var.opencti_connector_kms_arn
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



############################
# -- OpenCTI Connectors -- #
############################

#########################
# -- Core Connectors -- #
#########################
module "core_opencti_connectors" {
  source                      = "./modules/core_connectors"
  resource_prefix             = var.resource_prefix
  private_subnet_ids          = data.aws_subnets.private.ids
  connector_security_group_id = aws_security_group.opencti_connector.id
  ecs_cluster                 = aws_ecs_cluster.this.id
  halt_connector_lambda_arn   = module.lambda.halt_connector_lambda_arn
  log_retention               = var.log_retention

  # -- Required -- #
  opencti_version           = var.opencti_version
  opencti_platform_url      = var.opencti_platform_url
  opencti_connector_kms_arn = var.opencti_connector_kms_arn

  # -- Connectors -- #
  ex_imp_opencti_connector_image = var.ex_imp_opencti_connector_image
  ex_imp_opencti_connector_name  = var.ex_imp_opencti_connector_name
  ex_imp_opencti_cron_job        = var.ex_imp_opencti_cron_job

  ex_imp_mitre_connector_image = var.ex_imp_mitre_connector_image
  ex_imp_mitre_connector_name  = var.ex_imp_mitre_connector_name
  ex_imp_mitre_cron_job        = var.ex_imp_mitre_cron_job

  ex_imp_cve_connector_image = var.ex_imp_cve_connector_image
  ex_imp_cve_connector_name  = var.ex_imp_cve_connector_name
  ex_imp_cve_cron_job        = var.ex_imp_cve_cron_job
}

#########################
# -- External Import -- #
#########################

####################################
# -- Internal Export Connectors -- #
####################################

####################################
# -- Internal Import Connectors -- #
####################################

########################################
# -- Internal Enrichment Connectors -- #
########################################

#################
# -- Streams -- #
#################
