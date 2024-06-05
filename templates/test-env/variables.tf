#######################################################################
# Google Cloud Platform (GCP)
variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

#######################################################################
# Amazon Web Services (AWS)
variable "aws-region" {
  type        = string
  description = "A region in AWS."
  default     = "ap-northeast-2"
  # AWS regions mapping list:
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
}

#######################################################################
# Microsoft Azure (MS Azure / Azure)
variable "azure-region" {
  type        = string
  description = "A location (region) in MS Azure."
  default     = "koreacentral"
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md  
}

variable "azure-resource-group-name" {
  type        = string
  default     = "tr-rg-01"
  description = "A resource group name in an Azure subscription."
}