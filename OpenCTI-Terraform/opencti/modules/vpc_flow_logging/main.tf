##########################
# -- VPC Flow Logging -- #
##########################
resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.this.arn
  log_destination = aws_cloudwatch_log_group.this.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.resource_prefix}/vpc-flow-logs"
  retention_in_days = var.log_retention
}

resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "example"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.role_policy.json
}

data "aws_iam_policy_document" "role_policy" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
  }
}
