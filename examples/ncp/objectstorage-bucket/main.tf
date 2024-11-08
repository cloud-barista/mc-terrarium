terraform {

  # Required Tofu version
  required_version = "~>1.8.3"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "3.2.1"
    }
  }
}

provider "ncloud" {
  access_key  = var.ncloud_access_key
  secret_key  = var.ncloud_secret_key
  region      = "KR" # Set the desired region (e.g., "KR", "JP", etc.)
  support_vpc = true # Enable VPC support
}

# Declare variables
variable "ncloud_access_key" {
  description = "Naver Cloud Platform Access Key"
  type        = string
  default     = "" # Leave the default value empty
}

variable "ncloud_secret_key" {
  description = "Naver Cloud Platform Secret Key"
  type        = string
  default     = "" # Leave the default value empty
}

# Create object storage bucket
resource "ncloud_objectstorage_bucket" "tofu_bucket" {
  bucket_name = "tofu-bucket"
}
