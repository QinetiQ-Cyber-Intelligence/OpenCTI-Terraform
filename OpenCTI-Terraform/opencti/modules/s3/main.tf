########################
# -- S3 ALB Logging -- #
########################
data "aws_caller_identity" "current" {}

resource "random_string" "alb_logging" {
  length  = 6
  special = false
  numeric = false
  upper   = false
}


resource "aws_s3_bucket" "alb_logging" {
  bucket = "${var.resource_prefix}-logging-${random_string.alb_logging.result}"
  #checkov:skip=CKV_AWS_144:Region replication of Access Logs is not required.
  #checkov:skip=CKV_AWS_145:SSE:KMS is not supported by the Application Load Balancer at the time of writing, therefore ignored.
  #checkov:skip=CKV_AWS_18:Logging is not setup to avoid a recursive loop of logging on a S3 bucket used for ALB access logs.
}

resource "aws_s3_bucket_versioning" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logging" {
  bucket                  = aws_s3_bucket.alb_logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  policy = data.aws_iam_policy_document.alb_logging.json
}

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
data "aws_iam_policy_document" "alb_logging" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id_lb_logs}:root"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.alb_logging.arn}/${var.public_opencti_access_logs_s3_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

#########################
# -- MinIO S3 Bucket -- #
#########################
# Gateway Endpoint and Route Table association is defined in main.tf and the 'az_subnet' module.

resource "random_string" "minio" {
  length  = 6
  special = false
  numeric = false
  upper   = false
}

resource "aws_s3_bucket" "minio" {
  bucket = "${var.resource_prefix}-minio-${random_string.minio.result}"
  #checkov:skip=CKV_AWS_18:Logging is not a requirement on this S3 bucket.
  #checkov:skip=CKV_AWS_144:Region replication of MinIO S3 bucket is not required.
}

resource "aws_s3_bucket_public_access_block" "minio" {
  bucket                  = aws_s3_bucket.minio.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "minio" {
  bucket = aws_s3_bucket.minio.id
  versioning_configuration {
    status = "Enabled"
  }
}
