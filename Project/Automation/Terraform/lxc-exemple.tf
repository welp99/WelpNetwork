resource "proxmox_lxc" "<node>-<hostname>" {
  target_node  = "<node>"
  hostname     = "<hostname>"
  ostemplate   = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  password     = "<password>"
  unprivileged = true # Set to false if you want to run as root
  onboot       = true # Start the container on boot
  vmid         = "<vmid>"

  # LXC CPU Settings
  cores = 1
  cpulimit = 1
  cpuunits = 1024 # 1024 is the default value

  # LXC Memory Settings
  memory = 512
  swap = 0

  # LXC Network Settings
  network {
        name   = "eth0"
        bridge = "vmbr0"
        ip     = "<ip>/24"
        gw = "<Gateway IP>"
  }

  nameserver = "<DNS IP>"
  searchdomain = "<Domain>"

  ssh_public_keys = <<-EOT
    <SSH Key>
    EOT
  # Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }
}

