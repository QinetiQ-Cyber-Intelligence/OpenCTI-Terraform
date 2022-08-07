#############
# -- KMS -- #
#############
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "kms_policy" {
  #checkov:skip=CKV_AWS_109:Conditions have been written to ensure restricted KMS Access.
  #checkov:skip=CKV_AWS_111:Conditions have been written to ensure restricted KMS Write Access.
  statement {
    sid    = "Allow administration of key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "${var.opencti_kms_key_admin}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html#:~:text=Permissions%20reference.-,Resource,-(Required)%20In%20a
    resources = [
      "*"
    ]
  }
  statement {

    effect = "Allow"
    sid    = "Allow KMS Use by CloudWatch Log Groups"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html#:~:text=Permissions%20reference.-,Resource,-(Required)%20In%20a
    resources = [
      "*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:ti-opencti*"
      ]
    }
  }
  # Secrets Manager does not use grants to gain access to the KMS key, the policy also allows Secrets Manager to
  # create grants for the KMS key on the user's behalf and allows the account to revoke any grant that allows Secrets Manager to use the KMS key.
  statement {

    effect = "Allow"
    sid    = "Allow KMS Use from AWS Services"
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_caller_identity.current.account_id}"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html#:~:text=Permissions%20reference.-,Resource,-(Required)%20In%20a
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${data.aws_region.current.name}.amazonaws.com",
        "elasticfilesystem.${data.aws_region.current.name}.amazonaws.com",
        "elasticache.${data.aws_region.current.name}.amazonaws.com",
        "es.${data.aws_region.current.name}.amazonaws.com",
        "lambda.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}

resource "aws_kms_key" "this" {
  description         = "Global KMS key for use by OpenCTI & other resources"
  is_enabled          = true
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_policy.json
}

resource "aws_kms_alias" "my_kms_alias" {
  target_key_id = aws_kms_key.this.key_id
  name          = "alias/opencti-global"
}


###################################
# -- Connector OpenCTI KMS Key -- #
###################################
resource "aws_kms_key" "connector" {
  description         = "KMS key for use by OpenCTI Connectors."
  is_enabled          = true
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_policy.json
}

resource "aws_kms_alias" "connector" {
  target_key_id = aws_kms_key.this.key_id
  name          = "alias/opencti-connectors"
}
