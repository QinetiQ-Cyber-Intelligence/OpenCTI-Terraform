output "halt_connector_lambda_arn" {
  value       = aws_lambda_function.this.arn
  description = "The ARN of the Lambda function that will schedule AWS ECS OpenCTI Services."
}
