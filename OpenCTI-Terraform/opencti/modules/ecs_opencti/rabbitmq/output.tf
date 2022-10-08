output "rabbitmq_credentials_arn" {
  value       = aws_secretsmanager_secret_version.this.arn
  description = "The Secrets Manager credentials ARN used to access RabbitMQ by OpenCTI."
}