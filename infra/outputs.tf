output "live_website_url" {
  value       = module.compute.alb_dns_name
  description = "Paste this into Brave to see your Nginx server"
}

output "bastion_ssh_ip" {
  value       = module.compute.bastion_public_ip
  description = "Use this IP to securely tunnel into your environment"
}
