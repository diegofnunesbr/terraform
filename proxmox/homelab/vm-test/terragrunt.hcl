include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/proxmox/vm"
}

locals {
  regional_config = read_terragrunt_config(find_in_parent_folders("regional_config.hcl"))
}

inputs = {
  name                = "vm-test"
  node_name           = local.regional_config.locals.node_name
  vm_id               = 200
  template_vm_id      = 9000
  cpu_cores           = 2
  memory_mb           = 2048
  disk_datastore      = "local-lvm"
  disk_size_gb        = 20
  network_bridge      = "vmbr0"
  ip_address          = "192.168.0.10/24"
  gateway             = "192.168.0.1"
  cloud_init_recipes  = ["admins", "agents"]
}
