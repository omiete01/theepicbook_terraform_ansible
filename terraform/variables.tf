variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "The virtual network of the resources"
  type        = string
  default     = "epicbook"
}

variable "ec2_name" {
  description = "The name of the EC2 instance"
  type        = string
  default     = "epicbook-ec2"
}

variable "ec2_ami" {
  description = "The ami of the ec2 instance"
  type        = string
  default     = "ami-0ecb62995f68bb549" # Ubuntu AMI
}

variable "ec2_instance_type" {
  description = "The instance type of the ec2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_pair" {
  description = "The key pair of the ec2 instance"
  type        = string
  default     = "id_rsa"
}

variable "key_name" {
  description = "The key name of the ec2 instance"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "rds_name" {
  description = "The name of the RDS instance"
  type        = string
  default     = "epicbook-rds"
}

variable "rds_username" {
  description = "The username of the RDS instance"
  type        = string
  default     = "db_admin"
}

variable "rds_password" {
  description = "The password of the RDS instance"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "The instance class of the rds instance"
  type        = string
  default     = "db.t3.micro"
}
