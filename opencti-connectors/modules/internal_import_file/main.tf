resource "random_uuid" "internal_import_document" {}
module "internal_import_document" {
  source                      = "../../modules/templates/connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.in_imp_document_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster
  log_retention               = var.log_retention

  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  opencti_version               = var.opencti_version
  opencti_connector_image       = var.in_imp_document_connector_image
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_kms_arn     = var.opencti_connector_kms_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/internal_import_document.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.internal_import_document.id
  }))
}


resource "random_uuid" "internal_import_stix" {}
module "internal_import_stix" {
  source                      = "../../modules/templates/connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.in_imp_stix_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster
  log_retention               = var.log_retention

  opencti_connector_cpu_size    = 256
  opencti_connector_memory_size = 512
  opencti_version               = var.opencti_version
  opencti_connector_image       = var.in_imp_stix_connector_image
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_kms_arn     = var.opencti_connector_kms_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/internal_import_stix.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.internal_import_stix.id
  }))
}