# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information of the MySQL RDS instance in AWS."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    sql_db_detail = {
      # Basic Information
      instance_name        = aws_db_instance.instance.identifier        # "myrdsinstance"
      instance_resource_id = aws_db_instance.instance.id                # "db-YMJCVDFDANINUTBJJU63AZTY5Q"
      instance_spec        = aws_db_instance.instance.instance_class    # "db.t3.micro"
      location             = aws_db_instance.instance.availability_zone # "ap-northeast-2c"
      tags                 = aws_db_instance.instance.tags              # { "Name" = "myrdsinstance" }

      # Storage Configuration
      storage_type = aws_db_instance.instance.storage_type      # "gp2"
      storage_size = aws_db_instance.instance.allocated_storage # 20

      # Database Engine Information
      engine_name    = aws_db_instance.instance.engine         # "mysql"
      engine_version = aws_db_instance.instance.engine_version # "8.0.39"

      # Database Connection Details
      connection_endpoint   = aws_db_instance.instance.endpoint            # "myrdsinstance.chrkjg2ktom1.ap-northeast-2.rds.amazonaws.com:3306"
      connection_host       = aws_db_instance.instance.address             # "myrdsinstance.chrkjg2ktom1.ap-northeast-2.rds.amazonaws.com"
      connection_port       = aws_db_instance.instance.port                # 3306
      public_access_enabled = aws_db_instance.instance.publicly_accessible # true

      # Authentication
      admin_username = aws_db_instance.instance.username # "myrdsuser"
      # amdin_password = aws_db_instance.myinstance.password # "myrdsuser"

      provider_specific_detail = {
        provider            = "aws"
        region              = var.csp_region
        zone                = aws_db_instance.instance.availability_zone
        resource_identifier = aws_db_instance.instance.arn      # "arn:aws:rds:ap-northeast-2:635484366616:db:myrdsinstance"
        is_multi_az         = aws_db_instance.instance.multi_az # false

        status             = aws_db_instance.instance.status                 # "available"
        dns_zone_id        = aws_db_instance.instance.hosted_zone_id         # "ZLA2NUCOLGUUR"
        security_group_ids = aws_db_instance.instance.vpc_security_group_ids # ["sg-0af75bda5c889cea6"]
        subnet_group_name  = aws_db_instance.instance.db_subnet_group_name   # "tofu-main"
        storage_encrypted  = aws_db_instance.instance.storage_encrypted      # false
        storage_throughput = aws_db_instance.instance.storage_throughput     # 0
        storage_iops       = aws_db_instance.instance.iops                   # 0
        replicas           = aws_db_instance.instance.replicas               # []
      }
    }
  }
}
