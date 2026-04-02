# infra/modules/networking/outputs.tf

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "The ID of the Public Subnet"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "The ID of the Private Subnet"
}
output "public_subnet_2_id" {
  value       = aws_subnet.public_subnet_2.id
  description = "The ID of the second Public Subnet"
}

output "private_subnet_2_id" {
  value       = aws_subnet.private_subnet_2.id
  description = "The ID of the second Private Subnet"
}
