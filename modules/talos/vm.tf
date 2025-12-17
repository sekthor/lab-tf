resource "proxmox_virtual_environment_vm" "master_node" {
  
  depends_on = [ 
    fortios_firewall_policy.allow_zone_traffic,
    fortios_firewall_policy.allow_wan_traffic,
    fortios_firewall_policy.allow_dns_traffic,
    proxmox_virtual_environment_network_linux_vlan.vlan_prox,
    proxmox_virtual_environment_pool.cluster_pool
  ]

  count       = var.cluster_data.masters.count
  name        = format("${var.cluster_data.name}-m-%02d", count.index + 1)
  description = "Managed by Terraform"
  tags        = ["kubernetes", "master"]

  # round robin distribute vms to pve nodes
  node_name = var.cluster_data.target_nodes[count.index % length(var.cluster_data.target_nodes)]

  stop_on_destroy = true

  pool_id = var.cluster_data.name

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.cluster_data.vlan_ip, 10 + count.index)}/${split("/", var.cluster_data.vlan_ip)[1]}"
        gateway = cidrhost(var.cluster_data.vlan_ip, 1)
      }
    }
  }

  cpu {
    cores = var.cluster_data.masters.cores
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.cluster_data.masters.memory
    floating  = var.cluster_data.masters.memory
  }

  disk {
    datastore_id = "local-lvm"
    size = var.cluster_data.masters.disk
    interface = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = var.cluster_data.vlan_id
  }

  cdrom {
    file_id = "truenas-iso:iso/talos-qemu-${var.cluster_data.talos_version}.iso"
  }

  agent {
    enabled = false
  }

  boot_order = ["scsi0","ide3","net0"]
}

resource "proxmox_virtual_environment_vm" "worker_node" {

  depends_on = [ 
    fortios_firewall_policy.allow_zone_traffic,
    fortios_firewall_policy.allow_wan_traffic,
    fortios_firewall_policy.allow_dns_traffic,
    proxmox_virtual_environment_network_linux_vlan.vlan_prox,
    proxmox_virtual_environment_pool.cluster_pool
  ]

  count       = var.cluster_data.workers.count
  name        = format("${var.cluster_data.name}-w-%02d", count.index + 1)
  description = "Managed by Terraform"
  tags        = ["kubernetes", "worker"]

  # round robin distribute vms to pve nodes
  node_name = var.cluster_data.target_nodes[count.index % length(var.cluster_data.target_nodes)]

  stop_on_destroy = true

  pool_id = var.cluster_data.name

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.cluster_data.vlan_ip, 20 + count.index)}/${split("/", var.cluster_data.vlan_ip)[1]}"
        gateway = cidrhost(var.cluster_data.vlan_ip, 1)
      }
    }
  }

  cpu {
    cores = var.cluster_data.workers.cores
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.cluster_data.workers.memory
    floating  = var.cluster_data.workers.memory
  }

  disk {
    datastore_id = "local-lvm"
    size = var.cluster_data.workers.disk
    interface = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = var.cluster_data.vlan_id
  }

  cdrom {
    file_id = "truenas-iso:iso/talos-qemu-${var.cluster_data.talos_version}.iso"
  }

  agent {
    enabled = false
  }
  boot_order = ["scsi0","ide3","net0"]
}