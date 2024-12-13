output "message_broker_info" {
  description = "Information of the Amazon MQ Broker instance in AWS."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    message_broker_detail = {
      # Basic Information
      broker_name        = aws_mq_broker.message_broker.broker_name
      broker_id          = aws_mq_broker.message_broker.id
      engine_type        = aws_mq_broker.message_broker.engine_type
      engine_version     = aws_mq_broker.message_broker.engine_version
      host_instance_type = aws_mq_broker.message_broker.host_instance_type
      deployment_mode    = aws_mq_broker.message_broker.deployment_mode

      # Connection Details
      broker_endpoint     = aws_mq_broker.message_broker.instances[0].endpoints[0]
      publicly_accessible = aws_mq_broker.message_broker.publicly_accessible

      # Authentication
      username = var.username

      provider_specific_detail = {
        provider            = "aws"
        region              = var.csp_region
        resource_identifier = aws_mq_broker.message_broker.arn
        security_group_ids  = aws_mq_broker.message_broker.security_groups
        subnet_ids          = aws_mq_broker.message_broker.subnet_ids
        storage_type        = aws_mq_broker.message_broker.storage_type
      }
    }
  }
}
