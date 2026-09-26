terraform {
  backend "local" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-include-url"
    content      = "${var.cloud_init_url}/${join(",", var.cloud_init_recipes)}"
  }

  part {
    content_type = "text/cloud-config"
    content = "#cloud-config\n${yamlencode(merge({
      hostname         = var.name
      manage_etc_hosts = true
    }, var.cloud_init_extra))}"
  }
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}-cloud-init.yaml"
    data      = data.cloudinit_config.this.rendered
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}
