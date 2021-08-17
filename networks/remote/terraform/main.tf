
//versions.tf
terraform {
  required_version = ">=0.13"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

//provider.tf
provider "ibm" {
  ibmcloud_api_key = "JUbX8h2y6qu0QwJOXTfV0QZzNE1M06UCUQMa15-emISC"
}

//variables.tf
variable "name" {
  description = "Name of the Instance"
  type        = string
  default = "auto"
}

variable "location" {
  description = "Instance zone"
  type        = string
  default = "us-south-1"
}

variable "image" {
  description = "Image ID for the instance"
  type        = string
  //imageid for ubuntu-20-04-amd64
  default = "r006-396ef8b6-91a3-48ce-a83b-0c6f67105cad"
  //default = "ubuntu-20-04-amd64"
}

variable "profile" {
  description = "Profile type for the Instance"
  type        = string
  default =  "bx2-4x16"
}



/*
variable "ssh_keys" {
  description = "List of ssh key IDs to the instance"
  type        = list(string)
  default = ["<sshKeyID>"]
}

variable "vpc" {
  description = "VPC name"
  type        = string
  default = "ttvpc1"
}

variable "primary_network_interface" {
  description = "List of primary_network_interface that are to be attached to the instance"
  type = list(object({
    subnet               = string
    interface_name       = string
    security_groups      = list(string)
    primary_ipv4_address = string
  }))
}
*/

#####################################################
# Optional Parameters
#####################################################

variable "resource_group" {
  description = "Resource group name"
  type        = string
  default     = "Default"
}

variable "no_of_instances" {
  description = "number of Instances"
  type        = number
  default     = 3
}

variable "zones" {
  description = "Zones/DCs to launch in"
  type = list
  default = ["au-syd-1","in-che-1","jp-osa-1","jp-tok-1","kr-seo-1","eu-de-1","eu-gb-1","ca-tor-1","us-south-1","us-east-1","br-sao-1"]

/*
currently added zones / data centres
us-south-1
in-che-1
br-sao-1
ca-tor-1
us-east-1
eu-de-1
eu-gb-1
jp-osa-1
au-syd-1
jp-tok-1
*/


}

variable "vpc" {
  description = "VPC name"
  type        = string
  default = "dkgtest-vpc-dallas"
}

data "ibm_is_vpc" "vpc" {
  //name = var.vpc
  name = (var.vpc != null ? var.vpc : "dkgtest-vpc-dallas")
}

data "ibm_resource_group" "resource_group" {
  name = (var.resource_group != null ? var.resource_group : "Default")
}

resource "ibm_is_ssh_key" "aruntfkey1" {
  name       = "aruntfkey1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEjE3D3wQwOluRHhGmCplAdaoZGasrIBXoIgfcn35Z9e99ReYyiImoLvFBV186xXNoolFXVvo6SoUAYIcyM4tas0k9yj6lHz7IQrzdtLagPxwntkoeR+Hc1nNmES7cRWY0Bp7U5ZN8LFLh7FZbG4rYGAp1tI+IPSk9DSStv+kYnFWnge82DAsEIOAvhCeuN7wxpyqWPVdgh3fbQJoehEnAEbMRen1OcV1hUgfkwlXSvKOHcwWBu633WWG9tf+56SIbSyOSpzJs18EClnbRW5eOYrMHtlG13Yeo3lP0DTdsHFxiEcF7WQZXqX6+cm3x9MaknqH6pzlmCfrtzvYnCcjH5YW/qI3n7czjATgzD6O3imSUg5EIUj5wMtoV583PL/eF/3Ir1eGM0Bbu3pK04wzXLAb0LTg3dGi7vtXG/Ivov2tBNQHKlBiaNLReozdTkfhztUFmuw3xi90n9XHi2aXz1VXQlStUrf2Uh1nNev4Lr/FKQYNiOgzw7nBtLEpvDrXVaB+nuqNcVNdtY/0B5nQn11I6oIPpDdxRr1dSaERfJXkN3jca1PkuF6N5ban0aCKHPfp5b67Wns6aOV5ygMzYxnqsJi6G82hNYc0o2rOkWIiH+vlkPRsF08vf45EcPqgVqjEyiutPBDbhB8LL/bnA2zia3GKi9+KlkvLwqhgM+Q== arun2"
}

resource "ibm_is_subnet" "subnet1" {
  name                     = "aruntfsubnet1"
  vpc                      = data.ibm_is_vpc.vpc.id
  zone                     = var.location
  total_ipv4_address_count = 256
}

resource "ibm_is_instance" "cluster" {
//reqd parameters
//image,keys,primary_network_interface,profile,vpc,zone
  count = "${var.no_of_instances}"
  keys = [ibm_is_ssh_key.aruntfkey1.id]
  name = "${var.name}node${count.index}"
// using "ubuntu-20-04-amd64" =  "r006-396ef8b6-91a3-48ce-a83b-0c6f67105cad"
  image = var.image

//  zone = "${element(var.regions, count.index)}"
//    zone = "${var.regions.count.index}"
  zone = var.location
  profile = "${var.profile}"
  vpc = data.ibm_is_vpc.vpc.id

/*
  primary_network_interface {
    subnet          = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
*/

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    //primary_ipv4_address = "192.168.123.3"
  }

}

