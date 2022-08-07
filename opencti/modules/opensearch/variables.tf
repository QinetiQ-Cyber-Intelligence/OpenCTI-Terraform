#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy the SSM Jump Box into."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that OpenSearch can be deployed to."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS Key used for encryption."
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "The list of private CIDR ranges associated with the private Subnet IDs."
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "The number of days that a Secret in Secrets Manager can be recovered post deletion."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "accepted_security_group_ids" {
  type        = list(string)
  description = "A list of Security Groups that are allowed to access OpenSearch."
}

###########################
# -- OpenSearch Config -- #
###########################
variable "opensearch_master_instance_type" {
  type        = string
  description = "The instance type to use for master nodes in the OpenSearch domain."
}

variable "opensearch_master_count" {
  type        = string
  description = "The number of master nodes to use for the OpenSearch domain."
}

variable "opensearch_data_node_instance_count" {
  type        = string
  description = "The number of data nodes to use for the OpenSearch domain."
}

variable "opensearch_data_node_instance_type" {
  type        = string
  description = "The instance type to use for the data nodes in the OpenSearch domain."
}

variable "opensearch_warm_count" {
  type        = string
  description = "The number of warm nodes to use for the OpenSearch domain."
}
variable "opensearch_ebs_volume_size" {
  type        = number
  description = "The GB size of the EBS Volume for each OpenSearch data node."
}

variable "opensearch_warm_instance_type" {
  type        = string
  description = "The instance type to use for the warm nodes in the OpenSearch domain."
}

variable "opensearch_engine_version" {
  type        = string
  description = "The engine version of the OpenSearch domain."
}

variable "opensearch_field_data_heap_usage" {
  type        = string
  description = "The amount of JVM Heap that Field Data caching can use."
}

variable "opensearch_auto_tune" {
  type = object({
    start_time = string
    length     = string
  })
  description = "The configuration options for AWS OpenSearch Auto Tune."
}
