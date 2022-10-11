module "export_report_pdf_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-export-report-pdf"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "export-report-pdf"
  environment_variable_template = "./config/${var.environment}/connectors/export_report_pdf/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "external_import_cve_connector" {
  source                        = "./modules/templates/scheduled_connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-cve"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "external-import-cve"
  environment_variable_template = "./config/${var.environment}/connectors/external_import_cve/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
  eventbridge_cron              = {
    start = "cron(0 6 1 * ? *)",
    stop  = "cron(15 6 1 * ? *)"
  }
  halt_connector_lambda_arn = module.lambda.halt_connector_lambda_arn
}

module "external_import_mitre_connector" {
  source                        = "./modules/templates/scheduled_connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-mitre"
  opencti_connector_cpu_size    = 1024 # Boosted as testing has shown high compute consumption
  opencti_connector_memory_size = 2048
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "external-import-mitre"
  environment_variable_template = "./config/${var.environment}/connectors/external_import_mitre/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
  eventbridge_cron              = {
    start = "cron(0 6 1 * ? *)",
    stop  = "cron(15 6 1 * ? *)"
  }
  halt_connector_lambda_arn = module.lambda.halt_connector_lambda_arn
}

module "external_import_opencti_connector" {
  source                        = "./modules/templates/scheduled_connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-opencti"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "external-import-opencti"
  environment_variable_template = "./config/${var.environment}/connectors/external_import_opencti/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
  eventbridge_cron              = {
    start = "cron(0 6 1 * ? *)",
    stop  = "cron(15 6 1 * ? *)"
  }
  halt_connector_lambda_arn = module.lambda.halt_connector_lambda_arn
}

module "hatching_triage_sandbox_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-hatching-triage-sandbox"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "hatching-triage-sandbox"
  environment_variable_template = "./config/${var.environment}/connectors/hatching_triage_sandbox/environment_variables.hcl"
  secrets_template              = "./config/${var.environment}/connectors/hatching_triage_sandbox/secrets.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "intezer_sandbox_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-intezer-sandbox"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "intezer-sandbox"
  environment_variable_template = "./config/${var.environment}/connectors/intezer_sandbox/environment_variables.hcl"
  secrets_template              = "./config/${var.environment}/connectors/intezer_sandbox/secrets.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "sentinelone_threats_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-sentinelone-threats"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "sentinelone-threats"
  environment_variable_template = "./config/${var.environment}/connectors/sentinelone_threats/environment_variables.hcl"
  secrets_template              = "./config/${var.environment}/connectors/sentinelone_threats/secrets.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "import_document_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-import-document"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "import-document"
  environment_variable_template = "./config/${var.environment}/connectors/import_document/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "import_file_stix_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-import-file-stix"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "import-file-stix"
  environment_variable_template = "./config/${var.environment}/connectors/import_file_stix/environment_variables.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "virustotal_downloader_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-virustotal-downloader"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "virustotal-downloader"
  environment_variable_template = "./config/${var.environment}/connectors/virustotal_downloader/environment_variables.hcl"
  secrets_template              = "./config/${var.environment}/connectors/virustotal_downloader/secrets.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}

module "virustotal_connector" {
  source                        = "./modules/templates/connector_template"
  resource_prefix               = var.resource_prefix
  opencti_version               = var.opencti_version
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_image       = "opencti/connector-virustotal"
  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  private_subnet_ids            = data.aws_subnets.private.ids
  ecs_cluster                   = aws_ecs_cluster.this.id
  ecs_task_count                = 1
  connector_security_group_id   = aws_security_group.opencti_connector.id
  container_name                = "virustotal"
  environment_variable_template = "./config/${var.environment}/connectors/virustotal/environment_variables.hcl"
  secrets_template              = "./config/${var.environment}/connectors/virustotal/secrets.hcl"
  log_retention                 = var.log_retention
  email_domain                  = var.email_domain
  opencti_url                   = var.opencti_url
}
