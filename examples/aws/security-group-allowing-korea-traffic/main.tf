terraform {
  required_version = "~>1.8.3"

  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# Reference the ipv4.csv file
# https://xn--3e0bx5euxnjje69i70af08bea817g.xn--3e0b707e/jsp/statboard/IPAS/ovrse/natal/IPaddrBandCurrent.jsp?nationCode1=KR

# External data source for converting CSV file encoding
data "external" "convert_csv" {
  program = ["python3", "${path.module}/convert-file-encoding.py"]
}

locals {
  # Read the ipv4.csv file
  csv_content = file("${path.module}/ipv4.csv")

  # Split the CSV file into lines
  csv_lines = compact(split("\n", local.csv_content))

  # Filter the data to include only Korean IP addresses
  filtered_data = [
    for line in slice(local.csv_lines, 1, length(local.csv_lines)) :
    split(",", line)
    if length(split(",", line)) > 1 &&
    trimspace(line) != "" &&
    split(",", line)[1] == "KR"
  ]

  # Combine the IP address and CIDR prefix
  kr_cidrs = [
    for row in local.filtered_data :
    "${row[2]}${row[4]}"
  ]
}

# Output the Korean IP data statistics and sample
output "kr_ip_data" {
  description = "Korean IP data statistics and sample"
  value = {
    original_encoding = data.external.convert_csv.result.original_encoding
    total_count       = length(local.filtered_data)
    sample_data       = slice(local.filtered_data, 0, min(5, length(local.filtered_data)))
  }
}

# Output the Korean IP ranges in CIDR format
output "kr_ip_ranges" {
  description = "Korean IP ranges in CIDR format"
  value = {
    total_count = length(local.kr_cidrs)
    sample_data = slice(local.kr_cidrs, 0, min(5, length(local.kr_cidrs)))
  }
}

# Validate the CSV data
check "csv_data_validation" {
  assert {
    condition     = length(local.csv_lines) > 1
    error_message = "CSV file must contain at least a header row and one data row."
  }
}

resource "null_resource" "export_kr_cidrs" {
  provisioner "local-exec" {
    command = <<EOT
echo '${jsonencode(local.kr_cidrs)}' > ${path.module}/kr_cidrs.json
EOT
  }
}


# NOTE - The maximum number of rules per security group has been reached.
# ╷
# │ Error: updating Security Group (sg-027b0a3e44a9113c6) ingress rules: authorizing Security Group (ingress) rules: operation error EC2: AuthorizeSecurityGroupIngress, https response error StatusCode: 400, RequestID: 5215018d-7e7b-41ec-8356-56710d6725d0, api error RulesPerSecurityGroupLimitExceeded: The maximum number of rules per security group has been reached.
# │ 
# │   with aws_security_group.allow_traffic_in_korea,
# │   on main.tf line 74, in resource "aws_security_group" "allow_traffic_in_korea":
# │   74: resource "aws_security_group" "allow_traffic_in_korea" {
# │ 
# ╵

# resource "aws_security_group" "allow_traffic_in_korea" {
#   name        = "allow-traffic-in-korea"
#   description = "Allow all inbound traffic in Korea"

#   ingress {
#     description = "Allow all inbound traffic in Korea"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = local.kr_cidrs
#   }

#   tags = {
#     Name = "allow-traffic-in-korea"
#   }
# }
