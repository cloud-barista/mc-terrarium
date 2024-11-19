# Create S3 bucket
# Note: S3 buckets must have globally unique names
# Note: S3 automatically provides cross-AZ redundancy
resource "aws_s3_bucket" "object_storage" {
  bucket = "${var.terrarium_id}-bucket" # Replace with your own unique bucket name

  tags = {
    Name = "${var.terrarium_id}-bucket"
    # Environment = "Dev"
  }
}

# Block public access to S3 bucket
# Note: This is a security best practice for most use cases
resource "aws_s3_bucket_public_access_block" "object_storage_public_access" {
  bucket = aws_s3_bucket.object_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Advanced configurations

# # Enable versioning for S3 bucket
# # Note: Versioning cannot be disabled once enabled, only suspended
# resource "aws_s3_bucket_versioning" "object_storage_versioning" {
#   bucket = aws_s3_bucket.object_storage.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Configure server-side encryption for S3 bucket
# # Note: AES256 is the default AWS managed encryption
# resource "aws_s3_bucket_server_side_encryption_configuration" "object_storage_encryption" {
#   bucket = aws_s3_bucket.object_storage.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }


######################################################
# May need to set up VPC endpoint for S3 access later

# # Create VPC Endpoint for S3
# # Note: Gateway endpoint is free and provides secure access to S3 from VPC
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.tofu_example.id
#   service_name = "com.amazonaws.ap-northeast-2.s3" # Fixed value of S3 service name for ap-northeast-2 

#   tags = {
#     Name = "s3-endpoint"
#   }
# }

# # Associate VPC Endpoint with route table
# resource "aws_vpc_endpoint_route_table_association" "s3_endpoint" {
#   route_table_id  = aws_route_table.tofu_example.id
#   vpc_endpoint_id = aws_vpc_endpoint.s3.id
# }
