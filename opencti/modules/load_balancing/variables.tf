#################
# -- General -- #
#################

variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}
variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy the Load Balancers into."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that the Load Balancers can be deployed to."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The list of public Subnet IDs that the Load Balancers can be deployed to."
}
variable "private_cidr_blocks" {
  type        = list(string)
  description = "The list of private CIDR ranges associated with the private Subnet IDs."
}

variable "logging_s3_bucket" {
  type        = string
  description = "The S3 Bucket ARN used to house the public ALB Access Logs."
}

variable "public_opencti_access_logs_s3_prefix" {
  type        = string
  description = "The Prefix assigned to the S3 Bucket for public ALB Access Logs."
}

variable "network_load_balancer_ips" {
  type        = list(string)
  description = "A list of static IP addresses to be used by the NLB."
}

#########################
# -- Port Networking -- #
#########################

variable "opencti_platform_port" {
  type        = number
  description = "The port that OpenCTI Platform will run on."
}

variable "rabbitmq_management_port" {
  type        = number
  description = "The management port for RabbitMQ."
}

variable "rabbitmq_node_port" {
  type        = number
  description = "The AMQP port for RabbitMQ."
}

###############
# -- Other -- #
###############
variable "domain" {
  type        = string
  description = "The name of the R53 Domain to be used by the ALB."
}

variable "oidc_information" {
  type = object({
    authorization_endpoint = string,
    client_id              = string,
    client_secret          = string,
    issuer                 = string,
    token_endpoint         = string,
    user_info_endpoint     = string,
    redirect_uris          = string
  })
  description = "The OIDC Authentication information used by OpenCTI Platform and the ALB."
  sensitive   = true
}