output "opencti_platform_public_endpoint" {
  value       = module.load_balancing.public_application_load_balancer_dns
  description = "The Application Load Balancer Endpoint for OpenCTI."
}

output "opencti_platform_internal_endpoint" {
  value       = "http://${module.load_balancing.private_network_load_balancer_dns}:${var.opencti_platform_port}"
  description = "The HTTP URL for private VPC access to OpenCTI Platform."
}

output "opencti_connector_kms_key_arn" {
  value       = module.kms.kms_key_connector_arn
  description = "The KMS Key ARN used to encrypt OpenCTI Platform Connector Secrets."
}