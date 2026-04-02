output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The public URL of the Load Balancer"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The IP address to SSH into your Bastion Host"
}

output "app_server_id" {
  value       = aws_instance.app_server.id
  description = "The ID of the App Server for CloudWatch to monitor"
}
