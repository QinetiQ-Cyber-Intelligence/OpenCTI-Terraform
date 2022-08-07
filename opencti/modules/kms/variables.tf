#################
# -- General -- #
#################

variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "opencti_kms_key_admin" {
  type        = string
  description = "The allowed IAM Entity that can perform administrative tasks on the KMS Key. Root account is allowed."
}