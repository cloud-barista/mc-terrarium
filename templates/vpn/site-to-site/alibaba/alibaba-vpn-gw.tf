# VPN Gateway for Alibaba Cloud
resource "alicloud_vpn_gateway" "main" {
  vpn_gateway_name = "${var.vpn_config.terrarium_id}-vpn-gateway"
  vpc_id           = var.vpn_config.alibaba.vpc_id
  bandwidth        = "10"
  enable_ipsec     = true
  enable_ssl       = false
  vswitch_id       = var.vpn_config.alibaba.vswitch_id_1
  # disaster_recovery_vswitch_id는 선택사항으로 설정
  # 일부 리전/가용영역에서는 지원되지 않을 수 있음
  disaster_recovery_vswitch_id = try(var.vpn_config.alibaba.vswitch_id_2, null)

  # AWS 패턴을 참고한 타임아웃 및 라이프사이클 설정
  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.vpn_config.terrarium_id}-vpn-gateway"
    Terrarium   = var.vpn_config.terrarium_id
    Environment = "vpn"
  }
}
