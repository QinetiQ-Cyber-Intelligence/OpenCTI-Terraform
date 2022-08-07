output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "The Private Subnet ID created in this AZ."
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "The Public Subnet ID created in this AZ."
}
