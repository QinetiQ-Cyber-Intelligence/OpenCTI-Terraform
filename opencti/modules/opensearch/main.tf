####################
# -- OpenSearch -- #
####################
resource "time_static" "this" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_opensearch_domain" "this" {
  domain_name    = "${var.resource_prefix}-opensearch"
  engine_version = var.opensearch_engine_version
  cluster_config {
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = length(var.private_subnet_ids)
    }
    dedicated_master_enabled = true
    dedicated_master_count   = var.opensearch_master_count
    dedicated_master_type    = var.opensearch_master_instance_type

    instance_count = var.opensearch_data_node_instance_count
    instance_type  = var.opensearch_data_node_instance_type

    # Refer to config file for explanation
    # warm_count = var.opensearch_warm_count
    # warm_enabled = true
    # warm_type = var.opensearch_warm_instance_type
    # cold_storage_options = true
  }
  auto_tune_options { #The issue was here
    desired_state       = "ENABLED"
    rollback_on_disable = "NO_ROLLBACK"
    maintenance_schedule {
      start_at = timeadd(time_static.this.rfc3339, var.opensearch_auto_tune.length)
      duration {
        value = 2
        unit  = "HOURS"
      }
      cron_expression_for_recurrence = var.opensearch_auto_tune.start_time
    }
  }
  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_ebs_volume_size
    volume_type = "gp3" # Important to ensure sufficient IOPs
    iops        = 3000
  }
  advanced_options = {
    "indices.fielddata.cache.size" = var.opensearch_field_data_heap_usage
  }
  encrypt_at_rest {
    enabled    = true
  }
  node_to_node_encryption {
    enabled = true
  }
  vpc_options {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["username"]
      master_user_password = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["password"]
    }
  }
  log_publishing_options {
    enabled                  = true
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.index_slow.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }
  log_publishing_options {
    enabled                  = true
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.search_slow.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }
  depends_on = [aws_iam_service_linked_role.this]
}
resource "aws_iam_service_linked_role" "this" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "index_slow" {
  name              = "${var.resource_prefix}/opensearch/index-slow"
  retention_in_days = var.log_retention
}
resource "aws_cloudwatch_log_group" "search_slow" {
  name              = "${var.resource_prefix}/opensearch/search-slow"
  retention_in_days = var.log_retention
}

resource "aws_cloudwatch_log_resource_policy" "example" {
  policy_name     = "${var.resource_prefix}-opensearch-logging-policy"
  policy_document = data.aws_iam_policy_document.opensearch_logging.json
}

data "aws_iam_policy_document" "opensearch_logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "${aws_cloudwatch_log_group.search_slow.arn}:*",
      "${aws_cloudwatch_log_group.index_slow.arn}:*",
    ]

    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

###############################
# -- OpenSearch Networking -- #
###############################
resource "aws_security_group" "this" {
  name = "${var.resource_prefix}-opensearch-sg"
  #checkov:skip=CKV2_AWS_5:This is attached to AWS OpenSearch but not recognised by Checkov.
  description = "OpenSearch Access"
  vpc_id      = var.vpc_id
  ingress {
    description     = "OpenSearch HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.accepted_security_group_ids
  }
}

###########################
# -- OpenSearch Access -- #
###########################
resource "aws_opensearch_domain_policy" "main" {
  domain_name     = aws_opensearch_domain.this.domain_name
  access_policies = data.aws_iam_policy_document.access_policy.json
}

data "aws_iam_policy_document" "access_policy" {
  statement {
    actions   = ["es:ESHttp*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.resource_prefix}-opensearch/*"]
    # Regarding "*", protection is implemented by the Security Group.
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

################################
# -- OpenSearch Master User -- #
################################
resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.resource_prefix}-platform-opensearch-credentials"
  description             = "Opensearch master credentials for OpenCTI"
  recovery_window_in_days = var.secrets_manager_recovery_window
}

resource "random_password" "opensearch_password" {
  length      = 32
  min_special = 1
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = <<EOF
  {
    "username": "opensearch-master-user",
    "password": "${random_password.opensearch_password.result}"
  }
  EOF
}
