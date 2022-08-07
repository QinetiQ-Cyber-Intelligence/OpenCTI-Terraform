output "elasticache_endpoint_address" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  description = "The Endpoint address for Elasticache redis for Read and Write Ops."
}

output "elasticache_credentials_arn" {
  value       = aws_secretsmanager_secret_version.this.arn
  description = "The Secrets Manger credentials ARN for AWS Elasticache Redis."
}
