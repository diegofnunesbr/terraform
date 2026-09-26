variable "name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "template_vm_id" {
  type = number
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 2048
}

variable "disk_datastore" {
  type    = string
  default = "local-lvm"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  type = string
}

variable "gateway" {
  type = string
}

variable "cloud_init_recipes" {
  type    = list(string)
  default = ["admins"]
}

variable "cloud_init_url" {
  type    = string
  default = "https://cloud-init.diegofnunesbr.com"
}

variable "cloud_init_extra" {
  type    = any
  default = {}
}
