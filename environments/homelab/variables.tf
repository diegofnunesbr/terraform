variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type    = string
  default = "proxmox"
}

variable "template_vm_id" {
  type = number
}
