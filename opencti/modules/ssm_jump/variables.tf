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
  description = "The list of private Subnet IDs that the instance can be deployed to."
}