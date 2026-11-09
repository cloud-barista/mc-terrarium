# AWS AI Stack Migration Testbed - Root Configuration
# 10-Node Conference Demo Testbed (9 Source Nodes in 3x3 Clusters + 1 Platform Control Node)

module "ai_stack_testbed" {
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
  gpu_ami_id          = var.gpu_ami_id
  ai_service_root_dir = var.ai_service_root_dir
  ai_model_name       = var.ai_model_name
  allowed_cidr_blocks = var.allowed_cidr_blocks

  # Additional tags
  tags = var.tags
}

locals {
  # Filter out Cloud-Migrator / general nodes so only the 9 Source Nodes are exported for Source Group registration
  source_vm_keys = sort([
    for k, v in var.vm_configurations : k
    if !contains(["cloud-migrator", "general"], v.service_role)
  ])

  private_key_raw     = trimspace(module.ai_stack_testbed.ssh_info.private_key)
  private_key_oneline = replace(local.private_key_raw, "\n", "\\n")

  # CSV Header matching cm-butterfly & cm-beetle bulk import specification:
  # name,description,ip_address,ssh_port,user,password,private_key
  csv_header = "name,description,ip_address,ssh_port,user,password,private_key"

  csv_rows_private = [
    for k in local.source_vm_keys : format(
      "%s,\"%s\",%s,22,ubuntu,,\"%s\n\"",
      k,
      replace(coalesce(var.vm_configurations[k].description, "${var.vm_configurations[k].service_role} node"), "\"", "\"\""),
      module.ai_stack_testbed.vm_summary[k].private_ip,
      local.private_key_raw
    )
  ]

  csv_rows_public = [
    for k in local.source_vm_keys : format(
      "%s,\"%s\",%s,22,ubuntu,,\"%s\n\"",
      k,
      replace(coalesce(var.vm_configurations[k].description, "${var.vm_configurations[k].service_role} node"), "\"", "\"\""),
      module.ai_stack_testbed.vm_summary[k].public_ip,
      local.private_key_raw
    )
  ]

  # JSON array matching cm-beetle UX Lab (SourceMetadataExtraction.tsx) & cm-butterfly fields
  json_connections_private = [
    for k in local.source_vm_keys : {
      name        = k
      description = coalesce(var.vm_configurations[k].description, "${var.vm_configurations[k].service_role} node")
      ip_address  = module.ai_stack_testbed.vm_summary[k].private_ip
      ip          = module.ai_stack_testbed.vm_summary[k].private_ip
      ssh_port    = 22
      port        = 22
      user        = "ubuntu"
      password    = ""
      private_key = "${local.private_key_raw}\n"
    }
  ]

  json_connections_public = [
    for k in local.source_vm_keys : {
      name        = k
      description = coalesce(var.vm_configurations[k].description, "${var.vm_configurations[k].service_role} node")
      ip_address  = module.ai_stack_testbed.vm_summary[k].public_ip
      ip          = module.ai_stack_testbed.vm_summary[k].public_ip
      ssh_port    = 22
      port        = 22
      user        = "ubuntu"
      password    = ""
      private_key = "${local.private_key_raw}\n"
    }
  ]
}

# 1. Auto-save SSH Private Key (.pem)
resource "local_file" "private_key_pem" {
  content         = "${local.private_key_raw}\n"
  filename        = "${path.module}/private_key_ai_stack_testbed.pem"
  file_permission = "0600"
}

# 2. Auto-save Single-Line SSH Private Key (_oneline.pem)
resource "local_file" "private_key_oneline_pem" {
  content         = local.private_key_oneline
  filename        = "${path.module}/private_key_ai_stack_testbed_oneline.pem"
  file_permission = "0600"
}

# 3. Auto-save Source Connections CSV (Private IP - Recommended when Beetle/Honeybee runs on cloud-migrator)
resource "local_file" "source_connections_private_csv" {
  content         = "${join("\n", concat([local.csv_header], local.csv_rows_private))}\n"
  filename        = "${path.module}/source_connections_private.csv"
  file_permission = "0600"
}

# 4. Auto-save Source Connections CSV (Public IP - For external Beetle/Honeybee access)
resource "local_file" "source_connections_public_csv" {
  content         = "${join("\n", concat([local.csv_header], local.csv_rows_public))}\n"
  filename        = "${path.module}/source_connections_public.csv"
  file_permission = "0600"
}

# 5. Auto-save Source Connections JSON (Private IP - For Beetle UX Lab JSON Import)
resource "local_file" "source_connections_private_json" {
  content         = "${jsonencode(local.json_connections_private)}\n"
  filename        = "${path.module}/source_connections_private.json"
  file_permission = "0600"
}

# 6. Auto-save Source Connections JSON (Public IP - For Beetle UX Lab JSON Import)
resource "local_file" "source_connections_public_json" {
  content         = "${jsonencode(local.json_connections_public)}\n"
  filename        = "${path.module}/source_connections_public.json"
  file_permission = "0600"
}

# 7. Auto-save Source Connections YAML (Private IP - For Beetle UX Lab YAML Import)
resource "local_file" "source_connections_private_yaml" {
  content         = yamlencode(local.json_connections_private)
  filename        = "${path.module}/source_connections_private.yaml"
  file_permission = "0600"
}

# 8. Auto-save Source Connections YAML (Public IP - For Beetle UX Lab YAML Import)
resource "local_file" "source_connections_public_yaml" {
  content         = yamlencode(local.json_connections_public)
  filename        = "${path.module}/source_connections_public.yaml"
  file_permission = "0600"
}
