terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

module "vm_test" {
  source = "../../modules/proxmox-vm"

  name                  = "vm-test"
  node_name             = var.node_name
  vm_id                 = 200
  template_vm_id        = var.template_vm_id
  cpu_cores             = 2
  memory_mb             = 2048
  disk_datastore        = "local-lvm"
  disk_size_gb          = 20
  network_bridge        = "vmbr0"
  ip_address            = "192.168.0.10/24"
  gateway               = "192.168.0.1"
  cloud_init_snippet_id = "local:snippets/test-vm.yaml"
}
