output "opencti_platform_public_endpoint" {
  value       = (var.domain == "") ? module.load_balancing.public_application_load_balancer_dns : "https://${var.subdomain}.${var.environment}.${var.domain}"
  description = "The Application Load Balancer Endpoint for OpenCTI."
}

output "opencti_platform_internal_endpoint" {
  value       = "http://${module.load_balancing.private_network_load_balancer_dns}:${var.opencti_platform_port}"
  description = "The HTTP URL for private VPC access to OpenCTI Platform."
}
