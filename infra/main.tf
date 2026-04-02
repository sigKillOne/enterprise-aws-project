# infra/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # This points everything to the Mumbai data centers
}

# ---------------------------------------------------------
# THE ENTERPRISE ARCHITECTURE (Module Wiring)
# ---------------------------------------------------------

module "networking" {
  source = "./modules/networking"
}

module "database" {
  source            = "./modules/database"
  vpc_id            = module.networking.vpc_id
  private_subnet_id = module.networking.private_subnet_id
  private_subnet_2_id = module.networking.private_subnet_2_id
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  public_subnet_2_id = module.networking.public_subnet_2_id
  private_subnet_id  = module.networking.private_subnet_id
}

module "monitoring" {
  source        = "./modules/monitoring"
  app_server_id = module.compute.app_server_id
  alert_email   = var.my_alert_email
}
