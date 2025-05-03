variable "admin_username" {
  description = "The admin username for the VM"
  type        = string

}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
  sensitive   = true
  
}

variable "source_address_prefix" {
  description = "The source address prefix for the network security group rule, this will be your public IP address"
  type        = string
  
}