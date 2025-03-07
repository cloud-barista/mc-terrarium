# variables.tf
variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "testbed"
}

