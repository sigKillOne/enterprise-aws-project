# infra/modules/compute/variables.tf

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet"
  type        = string

}


variable "public_subnet_2_id" {
  description = "The ID of the second public subnet for the ALB"
  type        = string
}
