variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vpc_name" {
  description = "Name prefix for the VPC/Virtual Network"
  type        = string
  default     = "epicbook"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "epicbook-vm"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "mysql_name" {
  description = "Name of the MySQL server"
  type        = string
  default     = "epicbook-mysql"
}

variable "mysql_username" {
  description = "MySQL administrator username"
  type        = string
  default     = "mysqladmin"
}

variable "mysql_password" {
  description = "MySQL administrator password"
  type        = string
  sensitive   = true
}

variable "mysql_sku_name" {
  description = "MySQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}