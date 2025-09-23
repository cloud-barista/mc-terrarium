# variables.tf
variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

  default = "mig-testbed-01"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "ap-northeast-2" # Seoul region
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Additional CIDR blocks allowed for SSH and all protocols inbound access (VPC CIDR is automatically included)"
  default     = [] # Empty by default, VPC CIDR will be added automatically
}

# VM configuration information with service roles
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
      instance_type = "t3.small" # 2 vCPU, 2 GB RAM (closest to 4GB requirement)
      vcpu          = 2
      memory_gb     = 4
      service_role  = "nginx"
    }
    vm2 = {
      instance_type = "t3.xlarge" # 4 vCPU, 16 GB RAM (closest to requirement)
      vcpu          = 2
      memory_gb     = 16
      service_role  = "nfs"
    }
    vm3 = {
      instance_type = "t3.large" # 2 vCPU, 8 GB RAM (closest to requirement)
      vcpu          = 4
      memory_gb     = 8
      service_role  = "mariadb"
    }
    vm4 = {
      instance_type = "m5.xlarge" # 4 vCPU, 16 GB RAM
      vcpu          = 4
      memory_gb     = 16
      service_role  = "tomcat"
    }
    vm5 = {
      instance_type = "m5.2xlarge" # 8 vCPU, 32 GB RAM
      vcpu          = 8
      memory_gb     = 32
      service_role  = "haproxy"
    }
    vm6 = {
      instance_type = "m5.2xlarge" # 8 vCPU, 32 GB RAM (6th VM added)
      vcpu          = 8
      memory_gb     = 32
      service_role  = "general"
    }
  }
}
