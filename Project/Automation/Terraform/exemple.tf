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