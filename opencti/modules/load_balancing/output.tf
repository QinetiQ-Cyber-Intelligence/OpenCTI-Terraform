output "private_network_load_balancer_dns" {
  value       = aws_lb.network.dns_name
  description = "The Network Load Balancer private endpoint."
}

output "public_application_load_balancer_dns" {
  value       = aws_lb.application.dns_name
  description = "The publicly accessible URL of the Application Load Balancer."
}

output "rabbitmq_cluster_load_balancer_target_group_arn" {
  value       = aws_lb_target_group.rabbitmq_cluster.arn
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ Cluster."
}

output "rabbitmq_management_load_balancer_target_group_arn" {
  value       = aws_lb_target_group.rabbitmq_management.arn
  description = "The ARN of the Load Balancer Target Group routing traffic to RabbitMQ Management portal."
}

output "opencti_platform_load_balancer_target_group_arn" {
  value       = aws_lb_target_group.opencti_platform.arn
  description = "The ARN of the Load Balancer Target Group routing traffic to OpenCTI Platform."
}

output "opencti_platform_application_load_balancer_target_group_arn" {
  description = "The ARN of the Public Target Group."
  value       = aws_lb_target_group.this.arn
}

output "application_load_balancer_security_group" {
  value       = aws_security_group.this.id
  description = "Security Group ID of the public Application Load Balancer."
}

output "network_load_balancer_subnet_mapping" {
  value       = aws_lb.network.subnet_mapping
  description = "The statically allocated EIPs (subnet mapped addresses) used by the Network Load Balancer."
}