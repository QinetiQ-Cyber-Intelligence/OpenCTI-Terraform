resource "random_uuid" "internal_export_pdf" {}
module "internal_export_pdf" {
  source                      = "../../modules/templates/connector_template"
  resource_prefix             = var.resource_prefix
  container_name              = var.in_exp_pdf_connector_name
  private_subnet_ids          = var.private_subnet_ids
  connector_security_group_id = var.connector_security_group_id
  ecs_cluster                 = var.ecs_cluster
  log_retention               = var.log_retention

  opencti_connector_cpu_size    = 512
  opencti_connector_memory_size = 1024
  opencti_version               = var.opencti_version
  opencti_connector_image       = var.in_exp_pdf_connector_image
  opencti_platform_url          = var.opencti_platform_url
  opencti_connector_kms_arn     = var.opencti_connector_kms_arn

  environment_variable_def = jsondecode(templatefile(
    "./resources/container_env_definitions/internal_export_pdf.hcl",
    {
      OPENCTI_PLATFORM_URL = var.opencti_platform_url,
      RANDOM_UUID          = random_uuid.internal_export_pdf.id
  }))
}