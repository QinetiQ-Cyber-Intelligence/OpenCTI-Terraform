#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

####################
# -- Networking -- #
####################
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy networking components to."
}

variable "private_subnet_cidr" {
  type        = string
  description = "The CIDR block for the private subnet in this AZ."
}

variable "public_subnet_cidr" {
  type        = string
  description = "The CIDR block for the public subnet in this AZ."
}

variable "availability_zone" {
  type        = string
  description = "The Availability Zone the networking resources will be deployed to."
}

variable "public_route_table_id" {
  type        = string
  description = "The ID of the Public Route Table."
}

variable "vpc_s3_endpoint_id" {
  type        = string
  description = "The VPC Endpoint ID for the S3 service to be attached to private route tables."
}