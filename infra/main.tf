terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "PRIVATE" {
  name     = "PRIVATE"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "PRIVATE_CuteChatNet" {
  network_id   = hcloud_network.PRIVATE.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/8"
}

resource "hcloud_server" "CuteChatNode" {
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  depends_on = [
    hcloud_network_subnet.PRIVATE_CuteChatNet,
  ]
  count = 3
  labels = {"CuteChatNode":"${count.index}"}
  name = "CuteChatNode${count.index}"
  server_type = "cx11"
  image = "ubuntu-22.04"
  ssh_keys = ["test@test"]
  location = "nbg1"
  network {
    network_id = hcloud_network.PRIVATE.id    
  }
  user_data = <<-EOT
    #!/bin/bash
    sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config 
    systemctl restart sshd
    apt-get -y update
    apt-get -y full-upgrade
    apt-get -y install nginx
  EOT
}

resource "hcloud_load_balancer" "CuteChatLB" {
  depends_on = [
    hcloud_network_subnet.PRIVATE_CuteChatNet,
    hcloud_server.CuteChatNode,
  ]
  name               = "CuteChatLB"
  load_balancer_type = "lb11"
  location           = "nbg1"
}

resource "hcloud_load_balancer_network" "CuteChatLB_Network" {
  depends_on = [
    hcloud_network_subnet.PRIVATE_CuteChatNet,
    hcloud_server.CuteChatNode,
  ]
  load_balancer_id = hcloud_load_balancer.CuteChatLB.id
  network_id       = hcloud_network.PRIVATE.id
}

resource "hcloud_load_balancer_target" "CuteChatLB_Target" {
  depends_on = [
    hcloud_load_balancer_network.CuteChatLB_Network,
    hcloud_server.CuteChatNode,
  ]
  load_balancer_id = hcloud_load_balancer.CuteChatLB.id
  use_private_ip = true
  type      = "label_selector"
  label_selector = "CuteChatNode"
}

resource "hcloud_managed_certificate" "CuteChat_Cert" {
  name         = "CuteChat_Cert"
  domain_names = ["hello.kekw.services"]
}

resource "hcloud_load_balancer_service" "CuteChatLB_Service" {
  load_balancer_id = hcloud_load_balancer.CuteChatLB.id
  protocol         = "https"
  listen_port = 443
  destination_port = 80
  http {
    redirect_http = true
    certificates = [hcloud_managed_certificate.CuteChat_Cert.id]        
  }
}