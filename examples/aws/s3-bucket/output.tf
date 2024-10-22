# Output configurations
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.tofu_example.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.tofu_example.id
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.tofu_example.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.tofu_example.arn
}
