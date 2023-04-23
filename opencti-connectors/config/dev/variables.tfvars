tags = {
  ProjectOwner = "Undefined"
  Customer     = "Undefined"
  Project      = "OpenCTI"
  Company      = "Undefined"
  Environment  = "dev"
  Terraform    = true
}
# Must match that of the OpenCTI Core deployment
resource_prefix = "tf-opencti"
log_retention   = "1"

############################
# -- OpenCTI Deployment -- #
############################
# -- OpenCTI -- #
opencti_version           = "5.7.2" # or 5.7.2 or greater
opencti_connector_kms_arn = "" # Use the outputted KMS information from the Core OpenCTI deployment.
opencti_platform_url      = "" # Use the outputted Internal Load Balancer information from the Core OpenCTI deployment.
opencti_platform_port     = 4000

###################
# -- IMPORTANT -- #
###################
# The Connector Name must match that, that is stored in the Core OpenCTI deployment otherwise the connector deployment will fail when attempting to reach AWS Secrets Manager.

##################
# -- Required -- #
##################

# -- OpenCTI Core Connectors -- #
ex_imp_opencti_connector_image = "opencti/connector-opencti"
ex_imp_opencti_connector_name  = "external-import-opencti"
ex_imp_opencti_cron_job = {
  start = "cron(0 6 1 * ? *)",
  stop  = "cron(15 6 1 * ? *)"
}
ex_imp_mitre_connector_image = "opencti/connector-mitre"
ex_imp_mitre_connector_name  = "external-import-mitre"
ex_imp_mitre_cron_job = {
  start = "cron(0 6 1 * ? *)",
  stop  = "cron(15 6 1 * ? *)"
}
ex_imp_cve_connector_image = "opencti/connector-cve"
ex_imp_cve_connector_name  = "external-import-cve"
ex_imp_cve_cron_job = {
  start = "cron(0 7 */2 * ? *)",
  stop  = "cron(15 7 */2 * ? *)"
}

##################
# -- Optional -- #
##################

# -- OpenCTI External Import Connectors -- #
# Be aware that, its important to ensure the Core Connectors have been ingested before pulling further External Feeds.
# Ensure that enough time is provisioned (~1-2 hours)


# -- OpenCTI Internal Import Connectors -- #

# -- OpenCTI Internal Export Connectors -- #

# -- OpenCTI Internal Enrichment Connectors -- #
