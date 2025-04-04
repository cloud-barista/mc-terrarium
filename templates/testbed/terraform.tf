terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.42"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>5.21"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~>1.81.173"
    }
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "~>1.76.0"
    }
  }
}
