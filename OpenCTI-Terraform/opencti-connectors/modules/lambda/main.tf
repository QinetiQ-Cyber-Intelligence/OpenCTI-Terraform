data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "./resources/lambda/halt_connector"
  output_path = "./resources/lambda/halt_connector.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = "${var.resource_prefix}-halt-connector"
  handler          = "halt_connector.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = aws_iam_role.this.arn
  timeout          = 900
  architectures    = ["arm64"]
  #checkov:skip=CKV_AWS_115:Concurrency Limits are not required for this Lambda function.
  #checkov:skip=CKV_AWS_116:Dead Letter Queues are not required for this Lambda function.
  #checkov:skip=CKV_AWS_117:This Lambda is not defined within a VPC as it does not need to interact with the VPC.
  tracing_config {
    mode = "Active"
  }
}

################################
# -- Lambda Resource Policy -- #
################################
resource "aws_lambda_permission" "this" {
  statement_id  = "${var.resource_prefix}-eventbridge-connector-scheduler-exec"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/${var.resource_prefix}-*"
}

#########################
# -- Lambda IAM Role -- #
#########################

resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-lambda-halt-connector-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.resource_prefix}-lambda-halt-connector-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ecs:UpdateService"]
          Effect   = "Allow"
          Resource = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/${var.resource_prefix}-*"]
        },
        {
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
          Effect   = "Allow"
          Resource = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
        }
      ]
    })
  }
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
