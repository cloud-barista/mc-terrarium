# outputs.tf
output "aws_testbed_info" {
  description = "AWS, resource details"
  value       = length(module.aws) > 0 ? module.aws.testbed_info : {}
}

output "aws_testbed_ssh_info" {
  description = "AWS, SSH connection information"
  sensitive   = true
  value = {
    aws = try(module.aws.ssh_info, null)
  }
}
