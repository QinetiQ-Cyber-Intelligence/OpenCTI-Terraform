output "opencti_platform_token" {
  value       = aws_secretsmanager_secret_version.master_api_key.arn
  description = "The Secrets Manager Credential ARN containing the OpenCTI Platform API Key."
}

output "opencti_platform_security_group" {
  value       = aws_security_group.this.id
  description = "The Security Group attached to the OpenCTI Platform resource."
}
