terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.10.1"
    }
  }
}

provider "digitalocean" {
  token = "${var.DO_API_TOKEN}"
}

