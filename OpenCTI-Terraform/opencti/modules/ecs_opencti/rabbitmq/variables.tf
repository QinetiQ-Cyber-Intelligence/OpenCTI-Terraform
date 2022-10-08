#################
# -- General -- #
#################
variable "resource_prefix" {
  type        = string
  description = "Prefix for AWS Resources."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy RabbitMQ into."
}

variable "ecs_cluster" {
  type        = string
  description = "The ARN Value of the AWS ECS Cluster for OpenCTI."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private Subnet IDs that Fargate resources can be deployed to."
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "List of the private CIDR blocks."
}

variable "secrets_manager_recovery_window" {
  type        = number
  description = "The number of days that a Secret in Secrets Manager can be recovered post deletion."
}

variable "log_retention" {
  type        = string
  description = "The number of days that CloudWatch Logs are retained for."
}

variable "private_network_load_balancer_static_ips" {
  type        = list(string)
  description = "The Static IP addresses associated with the Private NLB."
}

variable "private_network_load_balancer_dns" {
  type        = string
  description = "The Network Load Balancer endpoint used for accessing other containers."
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Enable or disable the ECS Exec capability on ECS Fargate instances."
}

################################
# -- RabbitMQ Configuration -- #
################################

variable "rabbitmq_image_tag" {
  type        = string
  description = "The Docker Image tag for the RabbitMQ Container."
}

variable "rabbitmq_cluster_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ."
}

variable "rabbitmq_management_load_balancer_target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ Management portal."
}

variable "rabbitmq_management_port" {
  type        = number
  description = "The management port for RabbitMQ."
}

variable "rabbitmq_node_port" {
  type        = number
  description = "The AMQP port for RabbitMQ."
}

variable "rabbitmq_cpu_size" {
  type        = number
  description = "The amount of vCPU allocated for the RabbitMQ Container."
}

variable "rabbitmq_memory_size" {
  type        = number
  description = "The amount of memory allocated for the RabbitMQ Container."
}

variable "rabbitmq_queue_metric_name" {
  type        = string
  default     = "RabbitMQ Total Messages"
  description = "The name given to the CloudWatch metric that lists the total number of messages."
}

variable "rabbitmq_metric_namespace" {
  type        = string
  default     = "OpenCTI RabbitMQ"
  description = "The name given to the CloudWatch namespace for RabbitMQ metrics."
}