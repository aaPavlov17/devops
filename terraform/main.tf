terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    virtualbox = {
      source  = "eran132/vbox"
      version = "2.1.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "servers" {
  description = "сервера"
  type = map(object({
    role = string
    port = number
  }))
}

resource "local_file" "server_config" {
  for_each = var.servers

  filename = "${path.module}/generated/${each.key}.conf"
  content  = <<-EOT
        server_name = ${each.key}
        role = ${each.value.role}
        port = ${each.value.port}
    EOT

  file_permission = "0644"
}

resource "virtualbox_vm" "server" {
  name       = "devops-hw1"
  image      = "https://cloud-images.ubuntu.com/jammy/20261004/jammy-server-cloudimg-amd64-vagrant.box"
  cpus       = 2
  memory     = "2.0gib"
  status     = "running"
  boot_order = ["disk", "none", "none", "none"]

  network_adapter {
    type = "nat"

    port_forwarding {
      name       = "ssh"
      protocol   = "tcp"
      host_ip    = "127.0.0.1"
      host_port  = 2222
      guest_port = 22
    }
  }

  serial_port {
    slot = 0
    mode = "file"
    path = "/dev/null"
  }

  lifecycle {
    ignore_changes = [
      network_adapter[0].device,
      network_adapter[0].port_forwarding,
    ]
  }
}

output "generated_files" {
  description = "Созданные файлы"

  value = {
    for name, config in local_file.server_config :
    name => config.filename
  }
}