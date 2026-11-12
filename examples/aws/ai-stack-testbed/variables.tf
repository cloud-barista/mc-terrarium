variable "credential_profile" {
  type        = string
  description = "The name of the credential profile (holder) to use."
  default     = "admin"
}

# AWS AI Stack Migration Testbed - Root Variables

variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."
  default     = "ai-stack-testbed-01"

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
  description = "Default Ubuntu 22.04 LTS AMI ID for standard EC2 instances in ap-northeast-2"
  default     = "ami-0f3a440bbcff3d043" # Ubuntu 22.04 LTS in Seoul
}

variable "gpu_ami_id" {
  type        = string
  description = "GPU-ready Ubuntu 22.04 AMI ID for AI GPU instances (ai-webui) in ap-northeast-2 (used by AIMX)"
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
    root_disk_gb  = optional(number, 50)
    ami_id        = optional(string)
    description   = optional(string, "")
  }))
  description = "10-Node VM configurations (9 Source Nodes in 3x3 Clusters + 1 Cloud-Migrator Node)"

  default = {
    # ── 0. Cloud-Migrator Node (1 Node) ───────────────────────────────
    cloud-migrator = {
      instance_type = "m5.2xlarge"
      vcpu          = 8
      memory_gb     = 32
      root_disk_gb  = 100
      service_role  = "cloud-migrator"
      description   = "Cloud-Migrator Node (CM-Beetle, CB-Tumblebug, CB-Spider, CM-Honeybee, MC-Terrarium)"
    }

    # ── 1. AI Inference Cluster (3 Source Nodes) ──────────────────────
    ai-gpu-01 = {
      instance_type = "g4dn.xlarge" # 4 vCPU, 16 GiB RAM, 1x NVIDIA Tesla T4 (16GB VRAM)
      vcpu          = 4
      memory_gb     = 16
      root_disk_gb  = 100
      ami_id        = "ami-00ffffe72a332c865"
      service_role  = "ai-webui"
      description   = "AI Inference Primary - Ollama (:11434) + gemma4:e2b + bge-m3 + Kotaemon (:7860)"
    }
    ai-gpu-02 = {
      instance_type = "t3.xlarge" # Full GPU profile: g4dn.xlarge
      vcpu          = 4
      memory_gb     = 16
      root_disk_gb  = 80
      service_role  = "ai-worker"
      description   = "AI Inference Worker 1 - Ollama Runtime (:11434)"
    }
    ai-gpu-03 = {
      instance_type = "t3.xlarge" # Full GPU profile: g4dn.xlarge
      vcpu          = 4
      memory_gb     = 16
      root_disk_gb  = 80
      service_role  = "ai-worker"
      description   = "AI Inference Worker 2 - vLLM / Vector Worker (:8000, :11434)"
    }

    # ── 2. Analytics Compute Cluster (3 Source Nodes) ─────────────────
    data-master-01 = {
      instance_type = "t3.xlarge" # Full profile: m5.2xlarge
      vcpu          = 4
      memory_gb     = 16
      root_disk_gb  = 50
      service_role  = "spark-master"
      description   = "Analytics Compute Master - Spark / Airflow Coordinator (:8080, :7077)"
    }
    data-worker-01 = {
      instance_type = "t3.large" # Full profile: m5.xlarge
      vcpu          = 2
      memory_gb     = 8
      root_disk_gb  = 50
      service_role  = "spark-worker"
      description   = "Analytics Compute Worker - PySpark Worker (:8081, :7077)"
    }
    data-etl-01 = {
      instance_type = "t3.large" # Full profile: m5.xlarge
      vcpu          = 2
      memory_gb     = 8
      root_disk_gb  = 50
      service_role  = "etl"
      description   = "Analytics Compute ETL - Kafka / Batch ETL Preprocessing (:9092, :5044)"
    }

    # ── 3. Backend & DB Cluster (3 Source Nodes) ──────────────────────
    db-primary-01 = {
      instance_type = "t3.large" # Full profile: r5.xlarge
      vcpu          = 2
      memory_gb     = 8
      root_disk_gb  = 50
      service_role  = "postgres"
      description   = "Backend & DB - PostgreSQL Primary Database (:5432)"
    }
    backend-api-01 = {
      instance_type = "t3.medium" # Full profile: t3.large
      vcpu          = 2
      memory_gb     = 4
      root_disk_gb  = 50
      service_role  = "backend-api"
      description   = "Backend & DB - FastAPI / Nginx Application Server (:80, :443, :8000)"
    }
    storage-gateway-01 = {
      instance_type = "t3.medium" # Full profile: t3.large
      vcpu          = 2
      memory_gb     = 4
      root_disk_gb  = 50
      service_role  = "storage"
      description   = "Backend & DB - MinIO / NFS Storage Gateway (:9000, :9001, :2049)"
    }
  }

  validation {
    condition = alltrue([
      for vm_key, vm_config in var.vm_configurations :
      contains([
        "ai-webui",
        "ai-worker",
        "spark-master",
        "spark-worker",
        "etl",
        "postgres",
        "backend-api",
        "storage",
        "redis",
        "cloud-migrator",
        "nginx",
        "nfs",
        "mariadb",
        "tomcat",
        "haproxy",
        "general"
      ], vm_config.service_role)
    ])
    error_message = "Service role must be one of: ai-webui, ai-worker, spark-master, spark-worker, etl, postgres, backend-api, storage, redis, cloud-migrator, nginx, nfs, mariadb, tomcat, haproxy, general."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default = {
    Project     = "AI-Stack-Migration-Testbed"
    Environment = "Conference-Demo"
    ManagedBy   = "OpenTofu"
  }
}
