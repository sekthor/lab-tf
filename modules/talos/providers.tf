terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.89.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.10.0-beta.0"
    }
    fortios = {
      source  = "fortinetdev/fortios"
    }
  }
}
