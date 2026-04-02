output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The public URL of the Load Balancer"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The IP address to SSH into your Bastion Host"
}
