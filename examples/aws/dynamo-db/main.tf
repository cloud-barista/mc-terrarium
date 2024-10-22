# Required Terraform and provider versions
terraform {
  required_version = "~>1.8.3"

  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = "ap-northeast-2"
}

# Create VPC
# Note: Using a /16 CIDR block allows for future subnet expansion
resource "aws_vpc" "tofu_example_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tofu-example-vpc"
  }
}

# Create a subnet
# Note: Single subnet is sufficient for DynamoDB access via VPC endpoint
resource "aws_subnet" "tofu_example_subnet" {
  vpc_id            = aws_vpc.tofu_example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tofu-example-subnet"
  }
}

# Create Internet Gateway
# Note: Required for internet access from the VPC
resource "aws_internet_gateway" "tofu_example_igw" {
  vpc_id = aws_vpc.tofu_example_vpc.id

  tags = {
    Name = "tofu-example-igw"
  }
}

# Create route table
resource "aws_route_table" "tofu_example_route" {
  vpc_id = aws_vpc.tofu_example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tofu_example_igw.id
  }

  tags = {
    Name = "tofu-example-route"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "tofu_example_route_association" {
  subnet_id      = aws_subnet.tofu_example_subnet.id
  route_table_id = aws_route_table.tofu_example_route.id
}

# Create VPC Endpoint for DynamoDB
# Note: Gateway endpoint is free and provides secure access to DynamoDB from VPC
resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id       = aws_vpc.tofu_example_vpc.id
  service_name = "com.amazonaws.ap-northeast-2.dynamodb"

  tags = {
    Name = "dynamodb-endpoint"
  }
}

# Associate VPC Endpoint with route table
resource "aws_vpc_endpoint_route_table_association" "dynamodb_endpoint_route" {
  route_table_id  = aws_route_table.tofu_example_route.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_endpoint.id
}

# Create DynamoDB table
# Note: DynamoDB is a com.amazonaws.ap-northeast-2.dynamodb service that AWS manages for high availability
resource "aws_dynamodb_table" "tofu_example_table" {
  name           = "GameScores"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "GameTitle"
    type = "S"
  }

  attribute {
    name = "TopScore"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "tofu-example-table"
    Environment = "Dev"
  }
}

# Create auto scaling for DynamoDB table (Optional)
# Note: Only applicable when billing_mode is PROVISIONED
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.tofu_example_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70
  }
}

# Additional Notes:
# - DynamoDB is a regional service that AWS manages for high availability
# - VPC Endpoint provides secure access to DynamoDB without internet gateway
# - PROVISIONED billing mode with auto scaling is better for predictable workloads
# - Enable point-in-time recovery for data protection
# - Server-side encryption is recommended for data security
