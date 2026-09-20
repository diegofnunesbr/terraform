# terraform

Provisiona VMs no Proxmox via código, usando o provider [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox).
Terraform e Terragrunt vivem no mesmo repositório (mesmo padrão da
empresa): os módulos reutilizáveis ficam em `modules/`, e cada
provedor/site tem sua própria árvore com os `terragrunt.hcl` de verdade.
O cloud-init injetado em cada VM vem do repositório `cloud-init`.

## Pré-requisitos

- Terraform >= 1.5 e Terragrunt >= 0.60
- Um template de VM no Proxmox com cloud-init habilitado (ver seção abaixo)
- Um API Token do Proxmox dedicado ao Terraform (não usar `root@pam`)
- O arquivo de cloud-init já copiado pro storage de snippets do Proxmox
  (ver README do repositório `cloud-init`)

## Estrutura do repositório

```text
terraform/
├── modules/
│   └── proxmox/
│       └── vm/                     # módulo reutilizável de VM
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── proxmox/                         # provedor (site/nuvem)
    └── homelab/                     # "região"/site (só tem um, por enquanto)
        ├── terragrunt.hcl           # remote_state + gera o provider
        ├── regional_config.hcl      # config compartilhada do site (endpoint, node)
        └── vm-test/
            └── terragrunt.hcl       # instância real: aponta pro módulo + inputs
```

## Criar o template de VM (uma vez só)

No shell do Proxmox:

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

## Criar o API Token do Terraform (uma vez só)

No shell do Proxmox:

```bash
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role PVEAdmin
pveum user token add terraform@pve terraform --privsep 0
```

Guarde o token impresso (formato `terraform@pve!terraform=<segredo>`) - ele
só aparece uma vez.

## Uso

```bash
export PROXMOX_API_TOKEN="terraform@pve!terraform=REPLACE_ME"

cd proxmox/homelab/vm-test
terragrunt init
terragrunt plan
terragrunt apply
```

## Criar uma VM nova

1. Crie uma pasta nova em `proxmox/homelab/` (ex.: `vm-jenkins/`).
2. Copie o `terragrunt.hcl` de `vm-test/` como ponto de partida, ajustando
   `name`, `vm_id` e `ip_address`.
3. Rode `terragrunt init` na pasta nova.

Se um dia precisar de outro provedor/site (ex.: uma nuvem pública), crie
uma pasta irmã de `proxmox/` (ex.: `oracle/`), com seu próprio
`regional_config.hcl` e `terragrunt.hcl`.
