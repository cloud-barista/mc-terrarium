# variables.tf
variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

  default = "testbed-01"
}
