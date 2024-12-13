# Amazon MQ Broker (ActiveMQ)
resource "aws_mq_broker" "message_broker" {
  broker_name    = "${var.terrarium_id}-broker"
  engine_type    = "ActiveMQ" # RabbitMQ is also available
  engine_version = "5.17.6"   # Valid values: [5.18, 5.17.6, 5.16.7]
  # auto_minor_version_upgrade = true       # Brokers on [ActiveMQ] version [5.18] must have [autoMinorVersionUpgrade] set to [true]
  host_instance_type  = "mq.t3.micro"
  publicly_accessible = true

  user {
    username = var.username
    password = var.password
  }
}

# # Security Group for Amazon MQ
# resource "aws_security_group" "mq_sg" {
#   name_prefix = "tofu-mq-sg-"
#   description = "MQ Broker Security Group"
#   vpc_id      = var.csp_vnet_id

#   ingress {
#     from_port   = 5671
#     to_port     = 5671
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
