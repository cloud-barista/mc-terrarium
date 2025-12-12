terraform {
  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    openstack = {
      source  = "registry.opentofu.org/terraform-provider-openstack/openstack"
      version = "~>1.54"
    }
  }
}
