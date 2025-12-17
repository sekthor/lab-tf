# ===============================
# Talos machine secrets
# ===============================
resource "talos_machine_secrets" "secrets" {
  depends_on = [ proxmox_virtual_environment_vm.master_node ]
  talos_version = "v1.11.5"
}

# ===============================
# Master node configuration
# ===============================
data "talos_machine_configuration" "master" {
  talos_version      = var.cluster_data.talos_version
  kubernetes_version = var.cluster_data.kubernetes_version
  cluster_name       = var.cluster_data.name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${local.master_ips[0]}:6443"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
}

# ===============================
# Master node configuration
# ===============================
data "talos_machine_configuration" "worker" {
  talos_version      = var.cluster_data.talos_version
  kubernetes_version = var.cluster_data.kubernetes_version
  cluster_name       = var.cluster_data.name
  machine_type       = "worker"
  cluster_endpoint   = "https://${local.master_ips[0]}:6443"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
}


# ===============================
# Apply configuration to all master nodes
# ===============================
resource "talos_machine_configuration_apply" "masters" {
  for_each = toset(local.master_ips)
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.master.machine_configuration
  node                        = each.value
  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              vip = {
                ip = cidrhost(var.cluster_data.vlan_ip, 9)
              }
            }
          ]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "workers" {
  for_each = toset(local.worker_ips)
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value
}


resource "talos_machine_bootstrap" "master" {
  depends_on = [
    talos_machine_configuration_apply.masters
  ]
  node                 = local.master_ips[0]
  client_configuration = talos_machine_secrets.secrets.client_configuration
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_configuration_apply.masters
  ]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = local.master_ips[0]
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename = "kubeconfig.yaml"
}
