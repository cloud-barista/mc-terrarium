# AWS Migration Testbed - Root Variables

variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."
  default     = "mig-testbed-01"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.terrarium_id))
    error_message = "Terrarium ID must contain only alphanumeric characters and hyphens."
  }
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

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
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

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "vm_configurations" {
  type = map(object({
    instance_type = string
    vcpu          = number
    memory_gb     = number
    service_role  = string
  }))
  description = "VM configurations for migration testbed with service roles"
  
  default = {
    vm1 = {
      instance_type = "t3.small"
      vcpu          = 2
      memory_gb     = 4
      service_role  = "nginx"
    }
    vm2 = {
      instance_type = "t3.xlarge"
      vcpu          = 4
      memory_gb     = 16
      service_role  = "nfs"
    }
    vm3 = {
      instance_type = "t3.large"
      vcpu          = 2
      memory_gb     = 8
      service_role  = "mariadb"
    }
    vm4 = {
      instance_type = "m5.xlarge"
      vcpu          = 4
      memory_gb     = 16
      service_role  = "tomcat"
    }
    vm5 = {
      instance_type = "m5.2xlarge"
      vcpu          = 8
      memory_gb     = 32
      service_role  = "haproxy"
    }
    vm6 = {
      instance_type = "m5.2xlarge"
      vcpu          = 8
      memory_gb     = 32
      service_role  = "general"
    }
  }

  validation {
    condition = alltrue([
      for vm_key, vm_config in var.vm_configurations : 
      contains(["nginx", "nfs", "mariadb", "tomcat", "haproxy", "general"], vm_config.service_role)
    ])
    error_message = "Service role must be one of: nginx, nfs, mariadb, tomcat, haproxy, general."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default = {
    Project     = "Migration-Testbed"
    Environment = "Testing"
    ManagedBy   = "Terraform"
  }
}