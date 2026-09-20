# terraform

Provisiona VMs no Proxmox via código, usando o provider [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox).
O cloud-init injetado em cada VM vem do repositório `cloud-init`.

## Pré-requisitos

- Terraform >= 1.5
- Um template de VM no Proxmox com cloud-init habilitado (ver seção abaixo)
- Um API Token do Proxmox dedicado ao Terraform (não usar `root@pam`)
- O arquivo de cloud-init já copiado pro storage de snippets do Proxmox
  (ver README do repositório `cloud-init`)

## Estrutura do repositório

```text
terraform/
├── modules/
│   └── proxmox-vm/            # módulo reutilizável de VM
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── homelab/                # instância real: a VM de teste
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
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
cd environments/homelab
cp terraform.tfvars.example terraform.tfvars   # preencha com os valores reais
terraform init
terraform plan
terraform apply
```

**Nunca edite `terraform.tfvars.example`** com valores reais - ele é só o
template e fica versionado. `terraform.tfvars` (a cópia real) nunca vai pro
git (`.gitignore`).
