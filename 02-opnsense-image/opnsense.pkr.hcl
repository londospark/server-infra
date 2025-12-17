packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "opnsense" {
  boot_wait = "3s"
  boot_steps = [
    ["1", "Boot in multi user mode"],
    ["<wait3m>", "Waiting 3min for guest to start"],
    ["root<enter>opnsense<enter><wait3s>", "Login into the firewall"],
    ["1<enter><wait>", "Start manual interface assignment"],
    ["N<enter><wait>", "Do not configure LAGGs now"],
    ["N<enter><wait>", "Do not configure VLANs now"],
    ["vtnet0<enter><wait>", "Configure WAN interface"],
    ["<enter><wait>", "Skip LAN interface configuration"],
    ["<enter><wait>", "Skip Optional interface 1 configuration"],
    ["y<enter><wait>", "I want to proceed"],
    ["<wait30s>", "Wait for OPNSense to reload"],
    ["<wait>8<enter>", "Enter in shell"],
    [
      "curl -o /conf/config.xml http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.xml<enter><wait3s>",
      "Download config.xml"
    ],
    ["opnsense-installer<enter><wait>", "Run OPNsense Installer"],
    ["<enter><wait>", "Use default keymap"],
    ["<down><enter><wait><enter><wait3s>", "Select UFS disk"],
    ["<enter><wait><left><enter><wait5m>", "Select the disk and install OPNsense"],
    ["<enter><wait>opnsense<enter><wait>opnsense<enter><wait1m>", "Update root password"],
    ["<down><enter><wait><enter><wait2m>", "Complete install and wait 2min for guest to restart"],
    ["root<enter>opnsense<enter><wait3s>", "Log into the firewall"],
    ["8<enter><wait>pfctl -d<enter><wait>", "Disabling firewall"],
    [
      "curl -o /usr/local/etc/rc.d/firstboot http://{{ .HTTPIP }}:{{ .HTTPPort }}/first-boot.sh<enter><wait3s>",
      "Download first-boot.sh"
    ],
    [
      "chmod +x /usr/local/etc/rc.d/firstboot<enter>",
      "Add executable permission to firstboot script"
    ]
  ]
  shutdown_command = "shutdown<enter>"

  disk_size        = "8192M"
  disk_compression = true
  memory           = 2048
  http_directory   = "http"
  net_device       = "virtio-net"

  iso_checksum = "${var.ISO_CHECKSUM}"
  iso_urls = [
    "./iso/OPNsense-${var.VERSION}-dvd-amd64.iso",
  ]
  output_directory = "output"
  format           = "qcow2"

  communicator = "ssh"
  ssh_timeout  = "200m"
  ssh_port     = 22
  ssh_username = "root"
  ssh_password = "opnsense"

  headless = true

  vm_name = "opnsense-${var.VERSION}-proxmox.qcow2"
}

build {
  sources = ["source.qemu.opnsense"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "scripts/base.sh",
      "scripts/qemu-guest-agent.sh",
      "scripts/cloud-init.sh",
      "scripts/post-install.sh"
    ]
  }
}

variable "VERSION" {
  type    = string
  default = "25.7"
  validation {
    condition     = can(regex("^\\d{2}\\.\\d$", var.VERSION))
    error_message = "The version should be XX.X. Ex: 25.7."
  }
}

variable "ISO_CHECKSUM" {
  type    = string
  default = "sha1:e388904d39e4e9604a89111b8410c98474782a41"
  validation {
    condition     = can(regex("^\\w+:\\w+", var.ISO_CHECKSUM))
    error_message = "The ISO checksum should be <type>:<value>. Ex: sha1:2722ee32814ee722bb565ac0dd83d9ebc1b31ed9."
  }
}
