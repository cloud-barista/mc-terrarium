# variables.tf
variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

  default = "testbed-01"
}

variable "desired_providers" {
  type        = list(string)
  description = "List of providers to be used in the testbed."
  default     = ["aws", "gcp", "azure", "alibaba", "tencent", "ibm"]
}
