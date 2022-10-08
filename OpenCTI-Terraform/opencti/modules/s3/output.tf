output "logging_s3_bucket" {
  value       = aws_s3_bucket.alb_logging.id
  description = "The S3 Bucket name used for logging purposes such as Public Load Balancer."
}

output "minio_s3_bucket_name" {
  value       = aws_s3_bucket.minio.id
  description = "The S3 Bucket name used by OpenCTI as an object storage solution."
}

output "minio_s3_bucket_arn" {
  value       = aws_s3_bucket.minio.arn
  description = "The S3 Bucket ARN used by OpenCTI as an object storage solution."
}