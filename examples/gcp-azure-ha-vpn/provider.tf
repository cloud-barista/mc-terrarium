/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Required Terraform providers
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.60.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.50.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
}


# Provider block for Google specifies the configuration for the provider
# CAUTION: Manage your credentials carefully to avoid disclosure.
locals {
  # Read and assign credential JSON string
  my_gcp_credential = file("credential-gcp.json")
  # Decode JSON string and get project ID
  my_gcp_project_id = jsondecode(local.my_gcp_credential).project_id
}

provider "google" {
  credentials = local.my_gcp_credential

  region  = var.gcp_region
  project = var.gcp_project_id
}