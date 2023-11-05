terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.doctl-token
}

// ------------------ K3S main ------------------ 
resource "digitalocean_droplet" "k3s-droplet-main" {
  image              = "ubuntu-22-10-x64"
  name               = "${var.cluster-name}-k3s-main"
  size               = "s-4vcpu-8gb"
  ssh_keys           = [var.id-ssh-key]
  region             = var.region
  private_networking = true

  provisioner "remote-exec" {
    connection {
      host        = self.ipv4_address
      user        = "root"
      type        = "ssh"
      private_key = file("~/.ssh/id_rsa")
      timeout     = "2m"
    }

    inline = [
      "ssh-keyscan ${self.ipv4_address} >> $HOME/.ssh/known_hosts",
      "apt update -y",
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s-token-node} sh - "
    ]
  }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml .kube/config"
  }
  provisioner "local-exec" {
    command = "sed -i 's,127.0.0.1,${self.ipv4_address},g' ~/.kube/config"
  }
}

resource "digitalocean_floating_ip_assignment" "k3s-assignment-api-main" {
  ip_address = var.ip-main
  droplet_id = digitalocean_droplet.k3s-droplet-main.id
}

// ------------------ Agent n1 ------------------ 

resource "digitalocean_droplet" "k3s-droplet-agent-1" {
  image    = "ubuntu-22-10-x64"
  name     = "${var.cluster-name}-k3s-agent-1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [var.id-ssh-key]
  region   = var.region
  provisioner "remote-exec" {
    connection {
      host        = self.ipv4_address
      user        = "root"
      type        = "ssh"
      private_key = file("~/.ssh/id_rsa")
      timeout     = "2m"
    }
    inline = [
      "ssh-keyscan ${self.ipv4_address} >> $HOME/.ssh/known_hosts",
      "apt update -y",
      "curl -sfL https://get.k3s.io | K3S_URL=https://${resource.digitalocean_droplet.k3s-droplet-main.ipv4_address}:6443 K3S_TOKEN=${var.k3s-token-node} sh -"
    ]
  }
}

resource "digitalocean_floating_ip_assignment" "k3s-assignment-api-agent-1" {
  ip_address = var.ip-agent-1
  droplet_id = digitalocean_droplet.k3s-droplet-agent-1.id
}


// ------------------ Agent n2 ------------------ 


resource "digitalocean_droplet" "k3s-droplet-agent-2" {
  image    = "ubuntu-22-10-x64"
  name     = "${var.cluster-name}-k3s-agent-2"
  size     = "s-2vcpu-4gb"
  ssh_keys = [var.id-ssh-key]
  region   = var.region
  provisioner "remote-exec" {
    connection {
      host        = self.ipv4_address
      user        = "root"
      type        = "ssh"
      private_key = file("~/.ssh/id_rsa")
      timeout     = "2m"
    }
    inline = [
      "ssh-keyscan ${self.ipv4_address} >> $HOME/.ssh/known_hosts",
      "apt update -y",
      "curl -sfL https://get.k3s.io | K3S_URL=https://${resource.digitalocean_droplet.k3s-droplet-main.ipv4_address}:6443 K3S_TOKEN=${var.k3s-token-node} sh -"
    ]
  }
}

resource "digitalocean_floating_ip_assignment" "k3s-assignment-api-agent-2" {
  ip_address = var.ip-agent-2
  droplet_id = digitalocean_droplet.k3s-droplet-agent-2.id
}


