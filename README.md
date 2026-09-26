# terraform

Provisiona VMs no Proxmox via código, usando o provider [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox).
Terraform e Terragrunt vivem no mesmo repositório (mesmo padrão da
empresa): os módulos reutilizáveis ficam em `modules/`, e cada
provedor/site tem sua própria árvore com os `terragrunt.hcl` de verdade.
O cloud-init de cada VM vem do servidor de receitas do repositório
`cloud-init` (`https://cloud-init.diegofnunesbr.com/`), no mesmo modelo da
empresa: o módulo monta um user-data em duas partes (`cloudinit_config`,
provider `hashicorp/cloudinit`) e sobe pro Proxmox como snippet:

- `text/x-include-url` com `https://cloud-init.diegofnunesbr.com/<receitas>`
  (as receitas genéricas, escolhidas em `cloud_init_recipes`)
- `text/cloud-config` com o que é só daquela VM (`hostname` e o que vier
  em `cloud_init_extra`)

Ex.: `cloud_init_recipes = ["admins", "agents", "docker"]` - a VM já nasce
com os usuários (inclusive o `rundeck`), monitoramento no Mimir/Grafana e
Docker. Receitas disponíveis no README do repositório `cloud-init`.

## Pré-requisitos

- Terraform >= 1.5 e Terragrunt >= 0.60
- Um template de VM no Proxmox com cloud-init habilitado (ver seção abaixo)
- Um API Token do Proxmox dedicado ao Terraform (não usar `root@pam`)
- Acesso SSH ao host Proxmox via agente (`ssh-add -L` deve mostrar a
  chave) para o usuário configurado no bloco `ssh` do provider - o
  upload do snippet de cloud-init usa SSH, a API do Proxmox sozinha não
  suporta isso
- O servidor de receitas do repositório `cloud-init` no ar e acessível
  pela VM no primeiro boot (`https://cloud-init.diegofnunesbr.com/`)

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

(Ou pela interface: `Datacenter > Permissions > Users` com realm
`Proxmox VE authentication server`, permissão `PVEAdmin` em `/`, e em `API
Tokens` um token `terraform` com `Privilege Separation` desmarcado.)

O token impresso (formato `terraform@pve!terraform=<segredo>`) só aparece
uma vez - guarde direto no cofre (`pass`, ver README da sua máquina / nota
do `.bashrc`), colando o valor completo:

```bash
pass insert -m proxmox/api-token
```

Se perder o segredo, não tem como recuperar: remova o token
(`pveum user token remove terraform@pve terraform`), crie de novo e
sobrescreva no cofre com `pass insert -m -f proxmox/api-token`.

## Uso

O `terragrunt`/`terraform` do `.bashrc` é uma função que lê o token do
cofre só na hora de rodar (`PROXMOX_API_TOKEN="$(pass show proxmox/api-token)"`,
junto dos tokens da Cloudflare e do GitLab) - pede a senha do cofre uma
vez e ninguém precisa exportar nada:

```bash
cd proxmox/homelab/vm-test
terragrunt init
terragrunt plan
terragrunt apply
```

## Criar uma VM nova

1. Crie uma pasta nova em `proxmox/homelab/` (ex.: `vm-jenkins/`).
2. Copie o `terragrunt.hcl` de `vm-test/` como ponto de partida, ajustando
   `name`, `vm_id`, `ip_address` e as receitas em `cloud_init_recipes`
   (ex.: `["admins", "agents", "docker"]` - lista no README do repositório
   `cloud-init`).
3. Rode `terragrunt init` na pasta nova.

As chaves SSH (a sua e a do Rundeck) vêm da receita `admins` do servidor
de cloud-init - trocar uma chave é mudar a receita lá, não aqui.

Se um dia precisar de outro provedor/site (ex.: uma nuvem pública), crie
uma pasta irmã de `proxmox/` (ex.: `oracle/`), com seu próprio
`regional_config.hcl` e `terragrunt.hcl`.
