output "opencti_platform_security_group" {
  value       = module.opencti_platform.opencti_platform_security_group
  description = "The Security Group attached to the OpenCTI Platform resource."
}
