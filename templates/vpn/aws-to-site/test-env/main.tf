# providers.tf
terraform {
  required_version = "~>1.8.3"

  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # Seoul
}

provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = "asia-northeast3" # Seoul
}

# variables.tf
variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "test"
}

# vpc-aws.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-subnet"
    Environment = var.environment
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-rtb"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# ssh-key.tf
# SSH 키 생성
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# AWS 키 페어 생성
resource "aws_key_pair" "main" {
  key_name   = "${var.environment}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# AWS 보안 그룹
resource "aws_security_group" "main" {
  name        = "${var.environment}-sg"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-sg"
  }
}

# AWS Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# AWS 라우팅 테이블에 인터넷 게이트웨이 경로 추가
resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# AWS EC2 인스턴스 수정
resource "aws_instance" "main" {
  ami           = "ami-0f3a440bbcff3d043" # Ubuntu 22.04 LTS in Seoul
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.main.id]

  associate_public_ip_address = true

  tags = {
    Name = "${var.environment}-ec2"
  }
}

# vpc-gcp.tf
resource "google_compute_network" "main" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = "asia-northeast3"
  network       = google_compute_network.main.id
}

# GCP 방화벽 규칙
resource "google_compute_firewall" "main" {
  name    = "${var.environment}-firewall"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

# GCP VM 인스턴스
resource "google_compute_instance" "main" {
  name         = "${var.environment}-vm"
  machine_type = "e2-micro"
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" # Ubuntu 22.04 LTS
      size  = 20                                # GB
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.name

    access_config {
      // 공인 IP 자동 할당
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
  }
}

# outputs.tf
output "network_details" {
  description = "Network resource details"
  value = {
    aws = {
      vpc_id      = aws_vpc.main.id
      vpc_cidr    = aws_vpc.main.cidr_block
      subnet_id   = aws_subnet.main.id
      subnet_cidr = aws_subnet.main.cidr_block
    }
    gcp = {
      vpc_name    = google_compute_network.main.name
      subnet_name = google_compute_subnetwork.main.name
      subnet_cidr = google_compute_subnetwork.main.ip_cidr_range
      project_id  = jsondecode(file("credential-gcp.json")).project_id
    }
  }
}


# outputs.tf에 추가
output "ssh_info" {
  description = "SSH connection information"
  sensitive   = true
  value = {
    private_key = tls_private_key.ssh.private_key_pem
    aws = {
      public_ip  = aws_instance.main.public_ip
      private_ip = aws_instance.main.private_ip
      user       = "ubuntu" # Ubuntu 사용자로 변경
      command    = "ssh -i private_key.pem ubuntu@${aws_instance.main.public_ip}"
    }
    gcp = {
      public_ip  = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
      private_ip = google_compute_instance.main.network_interface[0].network_ip
      user       = "ubuntu" # Ubuntu 사용자로 변경
      command    = "ssh -i private_key.pem ubuntu@${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}"
    }
  }
}
