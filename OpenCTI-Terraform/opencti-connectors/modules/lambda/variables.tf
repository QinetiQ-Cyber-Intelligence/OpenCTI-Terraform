##################
# --  General -- #
##################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "cluster_name" {
  type        = string
  description = "The ID of the ECS Cluster to deploy to."
}
