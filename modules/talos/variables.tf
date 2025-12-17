variable "cluster_data" {
    type = object({
        name = string
        zone = string
        vlan_id = number
        vlan_ip = string
        target_nodes = list(string)
        talos_version = string
        kubernetes_version = string
        
        masters = object({
          count = number
          memory = number
          cores = number
          disk = number
        })

        workers = object({
          count = number
          memory = number
          cores = number
          disk = number
        })
    })


}

locals {
    cidr_netmask = "${split("/", var.cluster_data.vlan_ip)[1]}"

    master_ips = [
      for i in range(var.cluster_data.masters.count) : cidrhost(var.cluster_data.vlan_ip, 10 + i)
    ]

    worker_ips = [
      for i in range(var.cluster_data.workers.count) : cidrhost(var.cluster_data.vlan_ip, 20 + i)
    ]
}