output "kms_key_arn" {
  value       = aws_kms_key.this.arn
  description = "KMS Key ARN for use by OpenCTI"
}

output "kms_key_connector_arn" {
  value       = aws_kms_key.connector.arn
  description = "The KMS Key ARN used to encrypt OpenCTI Platform Connector Secrets."
}