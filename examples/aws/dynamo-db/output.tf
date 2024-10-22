# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.tofu_example_vpc.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.tofu_example_subnet.id
}

output "dynamodb_table_id" {
  description = "The ID of the DynamoDB table"
  value       = aws_dynamodb_table.tofu_example_table.id
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.tofu_example_table.arn
}
