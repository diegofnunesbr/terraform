locals {
  regional_config = read_terragrunt_config(find_in_parent_folders("regional_config.hcl"))
}

remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "proxmox" {
  endpoint  = "${local.regional_config.locals.proxmox_endpoint}"
  api_token = "${get_env("PROXMOX_API_TOKEN", "")}"
  insecure  = true
}
EOF
}
