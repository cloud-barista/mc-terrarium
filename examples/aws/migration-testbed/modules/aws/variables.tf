# AWS Migration Testbed Module - Variables

variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for subnet"
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for subnet"
  default     = "ap-northeast-2a"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
  default     = "ami-0f3a440bbcff3d043" # Ubuntu 22.04 LTS in Seoul
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Additional CIDR blocks allowed for SSH and all protocols inbound access (VPC CIDR is automatically included)"
  default     = []
}

variable "vm_configurations" {
  type = map(object({
    instance_type = string
    vcpu          = number
    memory_gb     = number
    service_role  = string
  }))
  description = "VM configurations for migration testbed with service roles"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
