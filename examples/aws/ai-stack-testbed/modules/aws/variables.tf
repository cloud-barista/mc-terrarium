variable "credential_profile" {
  type        = string
  description = "The name of the credential profile (holder) to use."
  default     = "admin"
}

# AWS AI Stack Migration Testbed Module - Variables

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
  description = "Default AMI ID for EC2 instances"
  default     = "ami-0f3a440bbcff3d043" # Ubuntu 22.04 LTS in Seoul
}

variable "gpu_ami_id" {
  type        = string
  description = "GPU-ready Ubuntu 22.04 AMI ID for AI GPU instances (ai-webui)"
  default     = "ami-00ffffe72a332c865" # Ubuntu 22.04 GPU AMI in Seoul
}

variable "ai_service_root_dir" {
  type        = string
  description = "Root directory on ai-gpu-01 for AIMX AI service stack (docker-compose.yml, ollama/, ktem_app_data/)"
  default     = "/opt/aimx/ai-service"
}

variable "ai_model_name" {
  type        = string
  description = "Ollama LLM model tag to pull and serve on ai-gpu-01"
  default     = "gemma4:e2b"
}

variable "ai_embedding_model" {
  type        = string
  description = "Ollama multilingual embedding model tag for Kotaemon RAG on ai-gpu-01"
  default     = "bge-m3"
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
    root_disk_gb  = optional(number, 50)
    ami_id        = optional(string)
    description   = optional(string, "")
  }))
  description = "VM configurations for AI stack migration testbed with service roles"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
