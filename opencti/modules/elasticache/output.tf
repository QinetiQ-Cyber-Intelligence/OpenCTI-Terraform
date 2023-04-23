output "elasticache_endpoint_address" {
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
  description = "The configuration endpoint address for Elasticache Redis."
}

output "elasticache_credentials_arn" {
  value       = aws_secretsmanager_secret_version.this.arn
  description = "The Secrets Manger credentials ARN for AWS Elasticache Redis."
}
