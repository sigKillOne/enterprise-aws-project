# infra/modules/database/variables.tf

variable "vpc_id" {
  description = "The ID of the VPC from the networking module"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet where databases will live"
  type        = string
}

variable "private_subnet_2_id" {
  description = "The ID of the second private subnet for DB high availability"
  type        = string
}
