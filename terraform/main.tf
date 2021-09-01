
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "random_pet" "names" {
  count = var.num
}

resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = file(var.ssh_pub_key_path)
}

resource "hcloud_server" "server" {
  count       = var.num
  name        = random_pet.names[count.index].id
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  labels = {
    type = "kekw"
  }
  ssh_keys = [hcloud_ssh_key.default.name]
  # user_data = file("${path.module}/user_data.tpl")
  # vars = {
  #   public_key = "${hcloud_ssh_key.default.public_key}"
  # }

}

resource "hcloud_load_balancer" "web_lb" {
  name               = "kekw_load_Balancer"
  load_balancer_type = "lb11"
  location           = "nbg1"
  labels = {
    type = "kekw"
  }

  dynamic "target" {
    for_each = hcloud_server.server
    content {
      type      = "server"
      server_id = target.value["id"]
    }
  }

  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_network" "hc_private" {
  name     = "hc_private"
  ip_range = var.ip_range
}

resource "hcloud_server_network" "web_network" {
  count     = var.num
  server_id = hcloud_server.server[count.index].id
  subnet_id = hcloud_network_subnet.hc_private_subnet.id
}

resource "hcloud_network_subnet" "hc_private_subnet" {
  network_id   = hcloud_network.hc_private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.ip_range
}

resource "hcloud_load_balancer_service" "web_lb_service" {
  load_balancer_id = hcloud_load_balancer.web_lb.id
  protocol         = "http"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "http"
    port     = 80
    interval = "10"
    timeout  = "10"
    http {
      path         = "/"
      status_codes = ["2??", "3??"]
    }
  }
}

resource "hcloud_load_balancer_network" "web_network" {
  load_balancer_id        = hcloud_load_balancer.web_lb.id
  subnet_id               = hcloud_network_subnet.hc_private_subnet.id
  enable_public_interface = "true"
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = hcloud_load_balancer.web_lb.ipv4
}

output "web_servers_status" {
  value = {
    for server in hcloud_server.server :
    server.name => server.status
  }
}

output "web_servers_ips" {
  value = {
    for server in hcloud_server.server :
    server.name => server.ipv4_address
  }
}

# Host file for ansible
resource "local_file" "hosts_file" {
  #https://www.bogotobogo.com/DevOps/Terraform/Terraform-Introduction-AWS-loops.php
  content  = join("\n", hcloud_server.server[*].ipv4_address)
  filename = "${path.module}/hosts"
}
