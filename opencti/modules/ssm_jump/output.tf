output "jump_box_security_group" {
  value       = aws_security_group.this.id
  description = "The Security Group ID used by the Jump Box."
}