#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy ElastiCache Redis into."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that ElastiCache can be deployed to."
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "The list of private CIDR ranges associated with the private Subnet IDs."
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "The number of days that a Secret in Secrets Manager can be recovered post deletion."
}

variable "accepted_security_group_ids" {
  type        = list(string)
  description = "A list of Security Groups that are allowed to access ElastiCache."
}

#############################
# -- Redis Configuration -- #
#############################
variable "elasticache_instance_type" {
  type        = string
  description = "The instance type to host Elasticache on."
}

variable "elasticache_replication_count" {
  type        = string
  description = "The number of replicated ElastiCache nodes."
}
variable "elasticache_redis_version" {
  type        = string
  description = "The Redis version to be used for AWS ElastiCache."
}

variable "elasticache_redis_port" {
  type        = string
  description = "The port that the Redis Cluster will be accessible on."
}

variable "elasticache_redis_snapshot_retention_limit" {
  type        = number
  description = "The number of days that ElastiCache Redis will retain automatic snapshots for before deleting them."
}

variable "elasticache_redis_snapshot_time" {
  type        = string
  description = "The time of day that ElastiCache Redis will start a snapshot of a read replica."
}

variable "elasticache_redis_maintenance_period" {
  type        = string
  description = "The time and day that ElastiCache Redis will begin performing maintenance tasks."
}