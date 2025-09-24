# AWS Migration Testbed - Root Configuration
# This configuration uses the AWS migration testbed module

# Migration Testbed Module
module "migration_testbed" {
  source = "./modules/aws"

  # Required variables
  terrarium_id      = var.terrarium_id
  aws_region        = var.aws_region
  vm_configurations = var.vm_configurations

  # Optional variables
  vpc_cidr            = var.vpc_cidr
  subnet_cidr         = var.subnet_cidr
  availability_zone   = var.availability_zone
  ami_id              = var.ami_id
  allowed_cidr_blocks = var.allowed_cidr_blocks

  # Additional tags
  tags = var.tags
}
