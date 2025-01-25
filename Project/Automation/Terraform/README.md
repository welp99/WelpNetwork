# Terraform 

Terraform is an open-source infrastructure as code software tool created by HashiCorp. It enables users to define and provision a datacenter infrastructure using a high-level configuration language known as Hashicorp Configuration Language, or optionally JSON.

Here is a simple guide on how to install Terraform on your system and how to use it to provision a datacenter infrastructure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Commands](#commands)
- [welp](#welp)

## Prerequisites

- Docker
- Docker Compose
- Proxmox VE
- Proxmox VE API Token

## Getting Started

1. Create a directory for Terraform and a docker compose file
```bash
mkdir -p ~/Terraform
cd ~/Terraform
nano docker-compose.yml
```

2. Add the following to the docker-compose.yml file
```yaml
services:
  terraform:
    image: hashicorp/terraform:1.10
    container_name: terraform
    volumes:
      - .:/terraform
    working_dir: /terraform
    environment:
      - TZ=Europe/Paris
    restart: always
    network_mode: host
```

3. Create provider.tf file

```bash
nano provider.tf
```

4. Add the following to the provider.tf file
```hcl
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

variable "proxmox_api_url" {
  type = string  
} 

variable "proxmox_api_token_id" {
  type = string  
}

variable "proxmox_api_token" {
  type = string
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure = true
}
```

5. Create a Credential file
```bash
nano credentials.auto.tfvars
```

6. Add the following to the credentials.auto.tfvars file
```hcl
proxmox_api_url = "https://proxmox.exemple.com:8006/api2/json"
proxmox_api_token_id = "root@pam!terraform"
proxmox_api_token = ""
```

7. Create a main.tf file
```bash
nano main.tf
```

8. Add the following to the main.tf file
```hcl
# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "<VM Name>" {

    # VM General Settings
    target_node = "proxmox01"
    vmid = "<VMID>"
    name = "<VM Name>"
    desc = "<VM Description>"
    automatic_reboot = true

    # VM Advanced General Settings
    onboot = true

    # VM OS Settings
    clone = "<Template Name>"

    # VM System Settings
    agent = 1

    # VM CPU Settings
    cores = 1
    sockets = 1
    cpu_type = "host"

    # VM Memory Settings
    memory = 1024

    # VM Network Settings
    network {
        id     = 0
        bridge = "vmbr0"
        model  = "virtio"
    }

    # Disk Configuration
    disks {
        scsi {
            scsi0 {
                disk {
                    size    = "20G"
                    storage = "local-lvm"
                }
            }
        }
        ide {
        # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
            ide2 {
                cloudinit {
                storage = "local-lvm"
                }
            }
        }
    }

    # VM Serial Settings
    serial {
        id = 0
    }

    # Contrôleur SCSI
    scsihw = "virtio-scsi-single"

    # VM Cloud-Init Settings
    os_type = "ubuntu"

    # (Optional) IP Address and Gateway
    ipconfig0 = "ip=<IP Address>/24,gw=<Gateway>"

    # (Optional) DNS Server
    nameserver = "<DNS>"

    # (Optional) Default User
    ciuser = "user"
    cipassword = "password"

    # (Optional) Upgrade the VM
    ciupgrade   = true

    # (Optional) Add your SSH KEY
    sshkeys = <<EOF
    ssh-rsa 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    EOF
}
```

##Commands

1. Run the following command to initialize the Terraform configuration
```bash
docker compose -f docker-compose.yml run --rm terraform init
```

2. Run the following command to check the Terraform configuration
```bash
docker compose -f docker-compose.yml run --rm terraform plan
```

3. Run the following command to apply the Terraform configuration
```bash
docker compose -f docker-compose.yml run --rm terraform apply
```

4. Run the following command to destroy the Terraform configuration
```bash
docker compose -f docker-compose.yml run --rm terraform destroy
```

5. Run the following command to connect to the Terraform container
```bash
docker compose -f docker-compose.yml run --rm terraform sh
```

## welp

In this guide, we have shown you how to install Terraform on your system. We have also shown you how to create a Terraform configuration file and how to use Terraform to provision a datacenter infrastructure. We hope that you have found this guide helpful and that you now have a better understanding of how to use Terraform to automate your infrastructure provisioning tasks.

