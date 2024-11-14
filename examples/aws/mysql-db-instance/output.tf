# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information for connecting to the MySQL RDS instance with dynamic variables."
  value = {
    sql_db_detail = {
      # Basic Information
      instance_name        = aws_db_instance.myinstance.identifier        # "myrdsinstance"
      instance_resource_id = aws_db_instance.myinstance.id                # "db-YMJCVDFDANINUTBJJU63AZTY5Q"
      instance_spec        = aws_db_instance.myinstance.instance_class    # "db.t3.micro"
      location             = aws_db_instance.myinstance.availability_zone # "ap-northeast-2c"
      tags                 = aws_db_instance.myinstance.tags              # { "Name" = "myrdsinstance" }

      # Storage Configuration
      storage_type = aws_db_instance.myinstance.storage_type      # "gp2"
      storage_size = aws_db_instance.myinstance.allocated_storage # 20

      # Database Engine Information
      engine_name    = aws_db_instance.myinstance.engine         # "mysql"
      engine_version = aws_db_instance.myinstance.engine_version # "8.0.39"

      # Database Connection Details
      connection_endpoint   = aws_db_instance.myinstance.endpoint            # "myrdsinstance.chrkjg2ktom1.ap-northeast-2.rds.amazonaws.com:3306"
      connection_host       = aws_db_instance.myinstance.address             # "myrdsinstance.chrkjg2ktom1.ap-northeast-2.rds.amazonaws.com"
      connection_port       = aws_db_instance.myinstance.port                # 3306
      public_access_enabled = aws_db_instance.myinstance.publicly_accessible # true

      # Authentication
      admin_username = aws_db_instance.myinstance.username # "myrdsuser"
      # amdin_password = aws_db_instance.myinstance.password # "myrdsuser"

      provider_specific_detail = {
        provider            = "aws"
        resource_identifier = aws_db_instance.myinstance.arn      # "arn:aws:rds:ap-northeast-2:635484366616:db:myrdsinstance"
        is_multi_az         = aws_db_instance.myinstance.multi_az # false

        status             = aws_db_instance.myinstance.status                 # "available"
        dns_zone_id        = aws_db_instance.myinstance.hosted_zone_id         # "ZLA2NUCOLGUUR"
        security_group_ids = aws_db_instance.myinstance.vpc_security_group_ids # ["sg-0af75bda5c889cea6"]
        subnet_group_name  = aws_db_instance.myinstance.db_subnet_group_name   # "tofu-main"
        storage_encrypted  = aws_db_instance.myinstance.storage_encrypted      # false
        storage_throughput = aws_db_instance.myinstance.storage_throughput     # 0
        storage_iops       = aws_db_instance.myinstance.iops                   # 0
        replicas           = aws_db_instance.myinstance.replicas               # []
      }
    }
  }
}

# 
# output "db_instance_all" {
#   description = "All information"
#   value       = aws_db_instance.myinstance
#   sensitive   = true
# }
