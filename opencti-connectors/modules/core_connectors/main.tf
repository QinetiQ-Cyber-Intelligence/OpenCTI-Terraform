resource "random_uuid" "external_import_opencti" {}
module "external_import_opencti" {
  source                      = "../../modules/templates/scheduled_connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.ex_imp_opencti_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster

  opencti_version           = var.opencti_version
  opencti_connector_image   = var.ex_imp_opencti_connector_image
  opencti_platform_url      = var.opencti_platform_url
  opencti_connector_kms_arn = var.opencti_connector_kms_arn
  log_retention             = var.log_retention

  eventbridge_cron          = var.ex_imp_opencti_cron_job
  halt_connector_lambda_arn = var.halt_connector_lambda_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/external_import_opencti.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.external_import_opencti.id
  }))
}

resource "random_uuid" "external_import_mitre" {}
module "external_import_mitre" {
  source                      = "../../modules/templates/scheduled_connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.ex_imp_mitre_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster

  opencti_version           = var.opencti_version
  opencti_connector_image   = var.ex_imp_mitre_connector_image
  opencti_platform_url      = var.opencti_platform_url
  opencti_connector_kms_arn = var.opencti_connector_kms_arn
  log_retention             = var.log_retention

  eventbridge_cron          = var.ex_imp_mitre_cron_job
  halt_connector_lambda_arn = var.halt_connector_lambda_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/external_import_mitre.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.external_import_mitre.id
  }))
}

resource "random_uuid" "external_import_cve" {}
module "external_import_cve" {
  source                      = "../../modules/templates/scheduled_connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.ex_imp_cve_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster

  opencti_connector_cpu_size    = 1024 # Boosted as testing has shown high compute consumption
  opencti_connector_memory_size = 2048
  opencti_version               = var.opencti_version
  opencti_connector_image       = var.ex_imp_cve_connector_image
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_kms_arn     = var.opencti_connector_kms_arn
  log_retention                 = var.log_retention

  eventbridge_cron          = var.ex_imp_cve_cron_job
  halt_connector_lambda_arn = var.halt_connector_lambda_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/external_import_cve.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.external_import_cve.id
  }))
}