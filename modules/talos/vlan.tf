resource "fortios_system_interface" "vlan_firewall" {
  name         = var.cluster_data.name
  ip           = var.cluster_data.vlan_ip
  vlanid       = var.cluster_data.vlan_id
  type         = "vlan"
  vdom         = "root"
  role         = "lan"
  interface    = var.cluster_data.zone
  description  = "vlan for kubernetes cluster ${var.cluster_data.name}"
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan_prox" {
  for_each  = toset(var.cluster_data.target_nodes)
  node_name = each.key
  name      = "vmbr0.${var.cluster_data.vlan_id}"
  comment   = "vlan ${var.cluster_data.name} (${var.cluster_data.vlan_id})"
}

resource "fortios_firewall_policy" "allow_dns_traffic" {
  depends_on = [fortios_system_interface.vlan_firewall]

  name     = "allow ${var.cluster_data.name} to ${var.cluster_data.zone} dns"
  action   = "accept"
  schedule = "always"
  status   = "enable"
  nat      = "enable"

  srcintf {
    name = var.cluster_data.name
  }

  dstintf {
    name = var.cluster_data.zone
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = "${var.cluster_data.zone}-dns"
  }

  service {
    name = "DNS"
  }
}

resource "fortios_firewall_policy" "allow_wan_traffic" {
  depends_on = [fortios_system_interface.vlan_firewall]

  name     = "allow ${var.cluster_data.name} to wan1"
  action   = "accept"
  schedule = "always"
  status   = "enable"
  nat      = "enable"

  srcintf {
    name = var.cluster_data.name
  }

  dstintf {
    name = "wan1" 
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = "all"
  }

  service {
    name = "ALL"
  }
}

resource "fortios_firewall_policy" "allow_zone_traffic" {
  depends_on = [fortios_system_interface.vlan_firewall]

  name     = "allow ${var.cluster_data.zone} to ${var.cluster_data.name}"
  action   = "accept"
  schedule = "always"
  status   = "enable"
  nat      = "enable"

  srcintf {
    name = var.cluster_data.zone
  }

  dstintf {
    name = var.cluster_data.name
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = "all"
  }

  service {
    name = "ALL"
  }
}