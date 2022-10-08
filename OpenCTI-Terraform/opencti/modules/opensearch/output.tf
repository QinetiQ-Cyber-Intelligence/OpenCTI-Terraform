output "opensearch_endpoint_address" {
  description = "The OpenSearch endpoint used to interact with the deployment."
  value       = aws_opensearch_domain.this.endpoint
}

output "opensearch_credentials_arn" {
  value       = aws_secretsmanager_secret_version.this.arn
  description = "The Secrets Manager credentials ARN for AWS OpenSearch."
}