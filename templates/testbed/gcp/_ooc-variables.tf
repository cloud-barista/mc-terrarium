# Overwrite on Copy (OoC): This file contains common variables used across multiple template directories.
# When picked and merged into a single working directory, this file will be
# overwritten if it exists in multiple source directories, resulting in a 
# single declaration of the variables.

variable "credential_profile" {
  type        = string
  description = "The name of the credential profile (holder) to use."
  default     = "admin"
}
