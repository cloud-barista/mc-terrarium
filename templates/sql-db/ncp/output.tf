
# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information of the MySQL instance in NCP."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    sql_db_detail = {
      # Basic Information
      instance_name        = ncloud_mysql.mysql.service_name       # "tofu-example-mysql"
      instance_resource_id = ncloud_mysql.mysql.id                 # "100457839"
      instance_spec        = ncloud_mysql.mysql.image_product_code # "SW.VMYSL.OS.LNX64.ROCKY.0810.MYSQL.B050"
      location             = ncloud_mysql.mysql.region_code        # "KR"
      tags                 = {}                                    # (if available)

      # Storage Configuration
      storage_type = ncloud_mysql.mysql.data_storage_type                                   # "SSD"
      storage_size = ncloud_mysql.mysql.mysql_server_list[0].data_storage_size / 1073741824 # 10 (Unit: GB)

      # Database Engine Information
      engine_name    = "mysql"                                # Always "mysql"
      engine_version = ncloud_mysql.mysql.engine_version_code # "MYSQL8.0.36"

      # Database Connection Details
      connection_endpoint   = "${ncloud_mysql.mysql.mysql_server_list[0].private_domain}:${ncloud_mysql.mysql.port}" # "db-2vpnbg.vpc-cdb.ntruss.com:3306"
      connection_host       = ncloud_mysql.mysql.mysql_server_list[0].private_domain                                 # "db-2vpnbg.vpc-cdb.ntruss.com"
      connection_port       = ncloud_mysql.mysql.port                                                                # 3306
      public_access_enabled = ncloud_mysql.mysql.mysql_server_list[0].is_public_subnet                               # true

      # Authentication
      admin_username = ncloud_mysql.mysql.user_name # "username"
      # admin_password = ncloud_mysql.mysql.user_password # "password"

      provider_specific_detail = {
        provider            = "ncp"
        resource_identifier = ncloud_mysql.mysql.id    # "100457839"
        is_ha               = ncloud_mysql.mysql.is_ha # true

        host_ip            = ncloud_mysql.mysql.host_ip            # "%"
        server_name_prefix = ncloud_mysql.mysql.server_name_prefix # "tofu-example-prefix"
        server_instances = [for server in ncloud_mysql.mysql.mysql_server_list : {
          name               = server.server_name        # "tofu-example-prefix-001-61we"
          role               = server.server_role        # "M" or "H"
          cpu_count          = server.cpu_count          # 2
          memory_size        = server.memory_size        # 4294967296
          create_date        = server.create_date        # "2024-11-14T19:29:51+0900"
          uptime             = server.uptime             # "2024-11-14T19:34:37+0900"
          server_instance_no = server.server_instance_no # "100457840"
        }]

        vpc_no                       = ncloud_mysql.mysql.vpc_no                       # "82836"
        subnet_no                    = ncloud_mysql.mysql.subnet_no                    # "185880"
        access_control_group_no_list = ncloud_mysql.mysql.access_control_group_no_list # ["218311"]

        backup_enabled               = ncloud_mysql.mysql.is_backup                    # true
        backup_time                  = ncloud_mysql.mysql.backup_time                  # "07:45"
        backup_file_retention_period = ncloud_mysql.mysql.backup_file_retention_period # 1

        is_multi_zone         = ncloud_mysql.mysql.is_multi_zone         # false
        is_storage_encryption = ncloud_mysql.mysql.is_storage_encryption # false
      }
    }
  }
}
