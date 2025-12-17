
# all VMs of the cluster will be put in the same resource pool 
resource "proxmox_virtual_environment_pool" "cluster_pool" {
  comment = "managed by terraform"
  pool_id = var.cluster_data.name
}