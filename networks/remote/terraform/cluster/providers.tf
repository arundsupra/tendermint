terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.10.1"
    }
  }
}

/*
terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
  required_version = ">= 0.12"
}


provider "ibm" {
  ibmcloud_api_key   = var.arun_ibmcloud_api_key
  region     = var.region
}
*/