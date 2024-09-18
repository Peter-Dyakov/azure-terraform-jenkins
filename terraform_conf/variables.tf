variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "location" {
  description = "Azure location for resources."
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group name."
  default     = "Peter-Candidate"
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  default     = "adminuser"
}


variable "acr_name" {
  description = "Name of the Azure Container Registry"
  default     = "acr2bcloud"
}

variable "vm_admin_ssh_key" {
  description = "SSH public key for the VM"
  type        = string
  default     = "~/.ssh/jenkins_vm_key.pub"
}

variable "ssh_private_key_path"{
      description = "SSH private key for the ssh to VM"
      type        = string
      default     = "~/.ssh/jenkins_vm_key"

}
