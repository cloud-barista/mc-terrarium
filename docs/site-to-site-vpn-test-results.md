# Site-to-site VPN test results using Terrarium

This document shares the site-to-site VPN test results using Terrarium.

## Test environment

- Terrarium 0.0.22+
- OpenBao 2.5.1

## Prerequisites

- Prepare CSP credentials
- Initialize OpenBao and register the CSP credentials by `init/init.sh`
- Run Terrarium and OpenBao by `make compose` (building image) or `make compose-up`

## Test

### Create a terrarium for testbed

- API: `POST /tr`
- Request body:

```json
{
  "description": "This terrarium is for testbed deployment",
  "name": "testbed01"
}
```

- Response

```json
{
  "name": "testbed01",
  "description": "This terrarium is for testbed deployment",
  "id": "testbed01"
}
```

### Create a terrarium for VPN

- API: `POST /tr`
- Request body:

```json
{
  "description": "This terrarium enriches ...",
  "name": "tr01"
}
```

- Response

```json
{
  "name": "tr01",
  "description": "This terrarium enriches ...",
  "id": "tr01"
}
```

---

### Create a testbed

- API: `POST /tr/{trId}/testbed`
- Path params:
  - trId: testbed01
- Request body:

```json
{
  "testbed_config": {
    "desired_providers": [
      "aws",
      "azure",
      "gcp",
      "alibaba",
      "tencent",
      "ibm",
      "dcs"
    ],
    "terrarium_id": ""
  }
}
```

Response:

> Omitted the raw response.

### Get the testbed

- API: `GET /tr/{trId}/testbed`
- Path params:
  - trId: testbed01
- Query params:
  - detail: refined

- Response

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "alibaba": {
      "private_ip": "10.3.1.200",
      "vpc_cidr": "10.3.0.0/16",
      "vpc_id": "vpc-mj7v3uqo7a16wzd5mifcu",
      "vswitch_1_cidr": "10.3.1.0/24",
      "vswitch_1_id": "vsw-mj7mifk8mnbaa0ig0493l",
      "vswitch_2_cidr": "10.3.2.0/24",
      "vswitch_2_id": "vsw-mj7o45k9u1k3vlu5ok30i"
    },
    "aws": {
      "private_ip": "10.0.1.226",
      "public_ip": "13.209.79.79",
      "subnet_cidr": "10.0.1.0/24",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_cidr": "10.0.0.0/16",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "azure": {
      "gateway_subnet_cidr": "10.2.2.0/24",
      "private_ip": "10.2.1.4",
      "region": "koreacentral",
      "resource_group_name": "testbed01-rg",
      "virtual_network_name": "testbed01-vnet"
    },
    "dcs": {
      "private_ip": "10.6.0.4",
      "public_ip": "xxx.xxx.xxx.157",
      "router_id": "68d569d6-1009-4a9b-b9fa-2ab0d8b45416",
      "subnet_id": "39b13c03-e0ff-4a1b-a51d-03da912fe5fd",
      "vm_id": "9251b783-755e-44f8-9c0d-a46685873d31",
      "vpc_id": "f9705e17-bf2a-42cf-985a-6128f56ffb6d"
    },
    "gcp": {
      "private_ip": "10.1.0.2",
      "project_id": "your-gcp-project-id",
      "subnet_cidr": "10.1.0.0/24",
      "subnet_name": "testbed01-subnet",
      "vpc_name": "testbed01-vpc"
    },
    "ibm": {
      "private_ip": "10.4.1.4",
      "subnet_cidr": "10.4.1.0/24",
      "subnet_id": "02h7-e5f3f2b7-b178-4140-9a3a-47a6aac885d8",
      "vpc_crn": "crn:v1:bluemix:public:is:au-syd:a/your-ibm-account-id::vpc:r026-d482e117-a7d3-4266-bd39-2bc6a7d93330",
      "vpc_id": "r026-d482e117-a7d3-4266-bd39-2bc6a7d93330"
    },
    "tencent": {
      "private_ip": "10.5.1.3",
      "subnet_cidr": "10.5.1.0/24",
      "subnet_id": "subnet-4rohuivp",
      "vpc_cidr": "10.5.0.0/16",
      "vpc_id": "vpc-41wmlzls"
    }
  }
}
```

---

### Create AWS to Azure VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "azure": {
        "bgp_asn": "65531",
        "bgp_peering_cidrs": {
          "to_alibaba": [
            "169.254.21.16/30",
            "169.254.21.20/30",
            "169.254.22.16/30",
            "169.254.22.20/30"
          ],
          "to_aws": [
            "169.254.21.0/30",
            "169.254.21.4/30",
            "169.254.22.0/30",
            "169.254.22.4/30"
          ],
          "to_gcp": [
            "169.254.21.8/30",
            "169.254.21.12/30",
            "169.254.22.8/30",
            "169.254.22.12/30"
          ],
          "to_ibm": [
            "169.254.21.32/30",
            "169.254.21.36/30",
            "169.254.22.32/30",
            "169.254.22.36/30"
          ],
          "to_tencent": [
            "169.254.21.24/30",
            "169.254.21.28/30",
            "169.254.22.24/30",
            "169.254.22.28/30"
          ]
        },
        "gateway_subnet_cidr": "10.2.2.0/24",
        "region": "koreacentral",
        "resource_group_name": "testbed01-rg",
        "virtual_network_name": "testbed01-vnet",
        "vpn_sku": "VpnGw1AZ"
      },
      "type": "azure"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to Azure VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65531",
          "id": "cgw-0b2974eaa8c8a5fcf",
          "ip_address": "4.217.129.90",
          "name": "tr01-azure-side-gw-1",
          "resource_type": "aws_customer_gateway"
        },
        {
          "bgp_asn": "65531",
          "id": "cgw-055686ec6a4afa8d9",
          "ip_address": "4.217.132.233",
          "name": "tr01-azure-side-gw-2",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-006592a62ec87bf52",
          "name": "tr01-to-azure-1",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.37.226.232",
          "tunnel2_address": "15.164.202.180"
        },
        {
          "id": "vpn-0d29814716c13da44",
          "name": "tr01-to-azure-2",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.39.87.205",
          "tunnel2_address": "43.202.186.35"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-0b57a72e78672aa54",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "azure": {
      "bgp_asn": "65531",
      "connections": [
        {
          "enable_bgp": true,
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/connections/tr01-to-aws-1",
          "name": "tr01-to-aws-1",
          "resource_type": "azurerm_virtual_network_gateway_connection",
          "type": "IPsec"
        },
        {
          "enable_bgp": true,
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/connections/tr01-to-aws-2",
          "name": "tr01-to-aws-2",
          "resource_type": "azurerm_virtual_network_gateway_connection",
          "type": "IPsec"
        },
        {
          "enable_bgp": true,
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/connections/tr01-to-aws-3",
          "name": "tr01-to-aws-3",
          "resource_type": "azurerm_virtual_network_gateway_connection",
          "type": "IPsec"
        },
        {
          "enable_bgp": true,
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/connections/tr01-to-aws-4",
          "name": "tr01-to-aws-4",
          "resource_type": "azurerm_virtual_network_gateway_connection",
          "type": "IPsec"
        }
      ],
      "local_gateways": [
        {
          "gateway_address": "3.37.226.232",
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/localNetworkGateways/tr01-aws-side-1",
          "name": "tr01-aws-side-1",
          "resource_type": "azurerm_local_network_gateway"
        },
        {
          "gateway_address": "15.164.202.180",
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/localNetworkGateways/tr01-aws-side-2",
          "name": "tr01-aws-side-2",
          "resource_type": "azurerm_local_network_gateway"
        },
        {
          "gateway_address": "3.39.87.205",
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/localNetworkGateways/tr01-aws-side-3",
          "name": "tr01-aws-side-3",
          "resource_type": "azurerm_local_network_gateway"
        },
        {
          "gateway_address": "43.202.186.35",
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/localNetworkGateways/tr01-aws-side-4",
          "name": "tr01-aws-side-4",
          "resource_type": "azurerm_local_network_gateway"
        }
      ],
      "public_ips": [
        {
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/publicIPAddresses/tr01-vpn-ip-1",
          "ip_address": "4.217.129.90",
          "name": "tr01-vpn-ip-1",
          "resource_type": "azurerm_public_ip"
        },
        {
          "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/publicIPAddresses/tr01-vpn-ip-2",
          "ip_address": "4.217.132.233",
          "name": "tr01-vpn-ip-2",
          "resource_type": "azurerm_public_ip"
        }
      ],
      "vpn_gateway": {
        "id": "/subscriptions/your-azure-subscription-id/resourceGroups/testbed01-rg/providers/Microsoft.Network/virtualNetworkGateways/tr01-vpn-gateway",
        "location": "koreacentral",
        "name": "tr01-vpn-gateway",
        "resource_type": "azurerm_virtual_network_gateway",
        "sku": "VpnGw1AZ"
      }
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to Azure VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

### Create AWS to GCP VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "gcp": {
        "bgp_asn": "65530",
        "region": "asia-northeast3",
        "vpc_network_name": "testbed01-vpc"
      },
      "type": "gcp"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to GCP VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65530",
          "id": "cgw-07e0f24263b394206",
          "ip_address": "34.64.66.219",
          "name": "tr01-gcp-side-gw-1",
          "resource_type": "aws_customer_gateway"
        },
        {
          "bgp_asn": "65530",
          "id": "cgw-0c8303c80a6c9d068",
          "ip_address": "34.64.128.30",
          "name": "tr01-gcp-side-gw-2",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-0782bf7c191fe3a5d",
          "name": "tr01-to-gcp-1",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.37.6.115",
          "tunnel2_address": "3.39.213.143"
        },
        {
          "id": "vpn-0f211f1a265bd39f4",
          "name": "tr01-to-gcp-2",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.36.156.239",
          "tunnel2_address": "52.79.117.93"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-0c540135851c9d2e5",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "gcp": {
      "external_gateway": {
        "description": "AWS-side VPN gateway",
        "id": "projects/your-gcp-project-id/global/externalVpnGateways/tr01-aws-side-vpn-gw",
        "interfaces": [
          {
            "id": 0,
            "ip_address": "3.37.6.115"
          },
          {
            "id": 1,
            "ip_address": "3.39.213.143"
          },
          {
            "id": 2,
            "ip_address": "3.36.156.239"
          },
          {
            "id": 3,
            "ip_address": "52.79.117.93"
          }
        ],
        "name": "tr01-aws-side-vpn-gw",
        "redundancy_type": "FOUR_IPS_REDUNDANCY",
        "resource_type": "google_compute_external_vpn_gateway"
      },
      "interfaces": [
        {
          "id": "asia-northeast3/tr01-router/tr01-interface-1",
          "ip_range": "169.254.78.90/30",
          "name": "tr01-interface-1",
          "resource_type": "google_compute_router_interface"
        },
        {
          "id": "asia-northeast3/tr01-router/tr01-interface-2",
          "ip_range": "169.254.239.94/30",
          "name": "tr01-interface-2",
          "resource_type": "google_compute_router_interface"
        },
        {
          "id": "asia-northeast3/tr01-router/tr01-interface-3",
          "ip_range": "169.254.25.158/30",
          "name": "tr01-interface-3",
          "resource_type": "google_compute_router_interface"
        },
        {
          "id": "asia-northeast3/tr01-router/tr01-interface-4",
          "ip_range": "169.254.90.206/30",
          "name": "tr01-interface-4",
          "resource_type": "google_compute_router_interface"
        }
      ],
      "peers": [
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/routers/tr01-router/tr01-peer-1",
          "name": "tr01-peer-1",
          "peer_asn": 64512,
          "peer_ip": "169.254.78.89",
          "resource_type": "google_compute_router_peer"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/routers/tr01-router/tr01-peer-2",
          "name": "tr01-peer-2",
          "peer_asn": 64512,
          "peer_ip": "169.254.239.93",
          "resource_type": "google_compute_router_peer"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/routers/tr01-router/tr01-peer-3",
          "name": "tr01-peer-3",
          "peer_asn": 64512,
          "peer_ip": "169.254.25.157",
          "resource_type": "google_compute_router_peer"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/routers/tr01-router/tr01-peer-4",
          "name": "tr01-peer-4",
          "peer_asn": 64512,
          "peer_ip": "169.254.90.205",
          "resource_type": "google_compute_router_peer"
        }
      ],
      "router": {
        "bgp_asn": "65530",
        "id": "projects/your-gcp-project-id/regions/asia-northeast3/routers/tr01-router",
        "name": "tr01-router",
        "network": "https://www.googleapis.com/compute/v1/projects/your-gcp-project-id/global/networks/testbed01-vpc",
        "resource_type": "google_compute_router"
      },
      "tunnels": [
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/vpnTunnels/tr01-tunnel-1",
          "interface": 0,
          "name": "tr01-tunnel-1",
          "peer_ip": "3.37.6.115",
          "resource_type": "google_compute_vpn_tunnel"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/vpnTunnels/tr01-tunnel-2",
          "interface": 1,
          "name": "tr01-tunnel-2",
          "peer_ip": "3.39.213.143",
          "resource_type": "google_compute_vpn_tunnel"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/vpnTunnels/tr01-tunnel-3",
          "interface": 0,
          "name": "tr01-tunnel-3",
          "peer_ip": "3.36.156.239",
          "resource_type": "google_compute_vpn_tunnel"
        },
        {
          "id": "projects/your-gcp-project-id/regions/asia-northeast3/vpnTunnels/tr01-tunnel-4",
          "interface": 1,
          "name": "tr01-tunnel-4",
          "peer_ip": "52.79.117.93",
          "resource_type": "google_compute_vpn_tunnel"
        }
      ],
      "vpn_gateway": {
        "id": "projects/your-gcp-project-id/regions/asia-northeast3/vpnGateways/tr01-ha-vpn-gw",
        "name": "tr01-ha-vpn-gw",
        "network": "https://www.googleapis.com/compute/v1/projects/your-gcp-project-id/global/networks/testbed01-vpc",
        "region": "asia-northeast3",
        "resource_type": "google_compute_ha_vpn_gateway"
      }
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to GCP VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

### Create AWS to Alibaba VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "alibaba": {
        "bgp_asn": "65532",
        "region": "ap-northeast-2",
        "vpc_id": "vpc-mj7v3uqo7a16wzd5mifcu",
        "vswitch_id_1": "vsw-mj7mifk8mnbaa0ig0493l",
        "vswitch_id_2": "vsw-mj7o45k9u1k3vlu5ok30i"
      },
      "type": "alibaba"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to Alibaba VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "alibaba": {
      "bgp_asn": "65532",
      "customer_gateways": [
        {
          "asn": "64512",
          "id": "cgw-mj7fh7p7bpb3zjf1ioigt",
          "ip_address": "3.35.123.231",
          "resource_type": "alicloud_vpn_customer_gateway"
        },
        {
          "asn": "64512",
          "id": "cgw-mj7lqxrzk1cv8yolq3kxc",
          "ip_address": "3.37.126.158",
          "resource_type": "alicloud_vpn_customer_gateway"
        },
        {
          "asn": "64512",
          "id": "cgw-mj7dlm924lb7i44dx48tr",
          "ip_address": "13.209.168.28",
          "resource_type": "alicloud_vpn_customer_gateway"
        },
        {
          "asn": "64512",
          "id": "cgw-mj7gpl1s7hmf3upfytfmk",
          "ip_address": "52.79.129.170",
          "resource_type": "alicloud_vpn_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "bgp_status": "",
          "id": "vco-mj7n9rvmazrr9ey64fyy9",
          "resource_type": "alicloud_vpn_connection",
          "tunnels": [
            {
              "bgp_status": "",
              "id": "tun-mj7spvm2jfqjzd31ajnaq",
              "peer_asn": "",
              "peer_bgp_ip": "",
              "resource_type": "alicloud_vpn_tunnel_options",
              "state": "active",
              "status": "ike_sa_not_established"
            },
            {
              "bgp_status": "",
              "id": "tun-mj75y2j4owo8w3ka7yh84",
              "peer_asn": "",
              "peer_bgp_ip": "",
              "resource_type": "alicloud_vpn_tunnel_options",
              "state": "active",
              "status": "ike_sa_not_established"
            }
          ]
        },
        {
          "bgp_status": "",
          "id": "vco-mj7fyzi7bl3h6nkx0hrgv",
          "resource_type": "alicloud_vpn_connection",
          "tunnels": [
            {
              "bgp_status": "",
              "id": "tun-mj70weaor6h7djwfteb80",
              "peer_asn": "",
              "peer_bgp_ip": "",
              "resource_type": "alicloud_vpn_tunnel_options",
              "state": "active",
              "status": "ike_sa_not_established"
            },
            {
              "bgp_status": "",
              "id": "tun-mj7b6kuf2to9z5g6y61xu",
              "peer_asn": "",
              "peer_bgp_ip": "",
              "resource_type": "alicloud_vpn_tunnel_options",
              "state": "active",
              "status": "ipsec_sa_established"
            }
          ]
        }
      ],
      "vpn_gateway": {
        "disaster_recovery_internet_ip": "47.80.3.185",
        "id": "vpn-mj7cv19zoc0atyhws3rn2",
        "internet_ip": "47.80.3.0",
        "resource_type": "alicloud_vpn_gateway"
      }
    },
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65532",
          "id": "cgw-0e045d86dcf38d6b7",
          "ip_address": "47.80.3.0",
          "name": "tr01-alibaba-side-gw-1",
          "resource_type": "aws_customer_gateway"
        },
        {
          "bgp_asn": "65532",
          "id": "cgw-010e3ab49add57883",
          "ip_address": "47.80.3.185",
          "name": "tr01-alibaba-side-gw-2",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-00df7f624d1ffba4d",
          "name": "tr01-to-alibaba-1",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.35.123.231",
          "tunnel2_address": "3.37.126.158"
        },
        {
          "id": "vpn-095c4d8bd167c2d9b",
          "name": "tr01-to-alibaba-2",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "13.209.168.28",
          "tunnel2_address": "52.79.129.170"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-0560698e8c8e4adeb",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to Alibaba VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

### Create AWS to Tencent VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "tencent": {
        "region": "ap-seoul",
        "subnet_id": "subnet-4rohuivp",
        "vpc_id": "vpc-41wmlzls"
      },
      "type": "tencent"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to Tencent VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65000",
          "id": "cgw-073bce9aad446fdd6",
          "ip_address": "43.128.136.176",
          "name": "tr01-tencent-side-gw-1",
          "resource_type": "aws_customer_gateway"
        },
        {
          "bgp_asn": "65000",
          "id": "cgw-0276a6c6ebbd17658",
          "ip_address": "150.109.232.16",
          "name": "tr01-tencent-side-gw-2",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-08ce584ee716a87ea",
          "name": "tr01-to-tencent-1",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "15.164.24.230",
          "tunnel2_address": "54.180.186.226"
        },
        {
          "id": "vpn-009765442e1f2fa7b",
          "name": "tr01-to-tencent-2",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "43.202.35.141",
          "tunnel2_address": "43.202.130.200"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-02abe22610d22d93f",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "tencent": {
      "customer_gateways": [
        {
          "id": "cgw-wydvxvnq",
          "name": "tr01-aws-side-gw-1",
          "public_ip_address": "15.164.24.230",
          "resource_type": "tencentcloud_vpn_customer_gateway"
        },
        {
          "id": "cgw-tfnbyvty",
          "name": "tr01-aws-side-gw-2",
          "public_ip_address": "54.180.186.226",
          "resource_type": "tencentcloud_vpn_customer_gateway"
        },
        {
          "id": "cgw-vngvbifj",
          "name": "tr01-aws-side-gw-3",
          "public_ip_address": "43.202.35.141",
          "resource_type": "tencentcloud_vpn_customer_gateway"
        },
        {
          "id": "cgw-24xbn1vs",
          "name": "tr01-aws-side-gw-4",
          "public_ip_address": "43.202.130.200",
          "resource_type": "tencentcloud_vpn_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "customer_gatway_id": "cgw-wydvxvnq",
          "health_check_local_ip": "169.254.128.2",
          "health_check_remote_ip": "169.254.128.1",
          "id": "vpnx-8rvt05a4",
          "ike_local_address": "43.128.136.176",
          "ike_remote_address": "15.164.24.230",
          "name": "tr01-to-aws-1",
          "resource_type": "tencentcloud_vpn_connection",
          "vpc_id": "vpc-41wmlzls",
          "vpn_gateway_id": "vpngw-e5modvbv"
        },
        {
          "customer_gatway_id": "cgw-tfnbyvty",
          "health_check_local_ip": "169.254.128.6",
          "health_check_remote_ip": "169.254.128.1",
          "id": "vpnx-32yjjekm",
          "ike_local_address": "43.128.136.176",
          "ike_remote_address": "54.180.186.226",
          "name": "tr01-to-aws-2",
          "resource_type": "tencentcloud_vpn_connection",
          "vpc_id": "vpc-41wmlzls",
          "vpn_gateway_id": "vpngw-e5modvbv"
        },
        {
          "customer_gatway_id": "cgw-vngvbifj",
          "health_check_local_ip": "169.254.129.2",
          "health_check_remote_ip": "169.254.129.1",
          "id": "vpnx-yio3l69b",
          "ike_local_address": "150.109.232.16",
          "ike_remote_address": "43.202.35.141",
          "name": "tr01-to-aws-3",
          "resource_type": "tencentcloud_vpn_connection",
          "vpc_id": "vpc-41wmlzls",
          "vpn_gateway_id": "vpngw-r0x8cjbr"
        },
        {
          "customer_gatway_id": "cgw-24xbn1vs",
          "health_check_local_ip": "169.254.129.6",
          "health_check_remote_ip": "169.254.129.1",
          "id": "vpnx-o4mpimal",
          "ike_local_address": "150.109.232.16",
          "ike_remote_address": "43.202.130.200",
          "name": "tr01-to-aws-4",
          "resource_type": "tencentcloud_vpn_connection",
          "vpc_id": "vpc-41wmlzls",
          "vpn_gateway_id": "vpngw-r0x8cjbr"
        }
      ],
      "vpn_gateways": [
        {
          "id": "vpngw-e5modvbv",
          "name": "tr01-vpn-gw-1",
          "public_ip": "43.128.136.176",
          "resource_type": "tencentcloud_vpn_gateway",
          "vpc_id": "vpc-41wmlzls"
        },
        {
          "id": "vpngw-r0x8cjbr",
          "name": "tr01-vpn-gw-2",
          "public_ip": "150.109.232.16",
          "resource_type": "tencentcloud_vpn_gateway",
          "vpc_id": "vpc-41wmlzls"
        }
      ]
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to Tencent VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

### Create AWS to IBM VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "ibm": {
        "region": "au-syd",
        "subnet_id": "02h7-e5f3f2b7-b178-4140-9a3a-47a6aac885d8",
        "vpc_cidr": "10.4.1.0/24",
        "vpc_id": "r026-d482e117-a7d3-4266-bd39-2bc6a7d93330"
      },
      "type": "ibm"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to IBM VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined
  - refresh: true

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65000",
          "id": "cgw-08dd9f2116c9e2986",
          "ip_address": "159.23.99.168",
          "name": "tr01-ibm-side-gw-1",
          "resource_type": "aws_customer_gateway"
        },
        {
          "bgp_asn": "65000",
          "id": "cgw-0ba8ddb1894772773",
          "ip_address": "159.23.99.169",
          "name": "tr01-ibm-side-gw-2",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-09fd0a079f53ce2ac",
          "name": "tr01-to-ibm-1",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.36.4.163",
          "tunnel2_address": "54.116.86.189"
        },
        {
          "id": "vpn-04ab68bc4ac25d3ed",
          "name": "tr01-to-ibm-2",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.38.58.86",
          "tunnel2_address": "43.201.203.130"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-0ac3ae34d77415b2c",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "ibm": {
      "vpn_connections": [
        {
          "crn": "",
          "gateway_connection": "02h7-90d81e40-4fbf-4538-85ab-ed9e93a325c8",
          "id": "02h7-e899e14a-7ef2-4fbf-9f09-210e6a91e0a5/02h7-90d81e40-4fbf-4538-85ab-ed9e93a325c8",
          "mode": "route",
          "name": "tr01-to-aws-1",
          "resource_type": "ibm_is_vpn_gateway_connection",
          "status": "up",
          "status_reasons": [],
          "tunnels": [
            {
              "address": "159.23.99.168",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            },
            {
              "address": "159.23.99.169",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            }
          ]
        },
        {
          "crn": "",
          "gateway_connection": "02h7-fbb04010-5858-42de-87b2-911f98ecd38d",
          "id": "02h7-e899e14a-7ef2-4fbf-9f09-210e6a91e0a5/02h7-fbb04010-5858-42de-87b2-911f98ecd38d",
          "mode": "route",
          "name": "tr01-to-aws-2",
          "resource_type": "ibm_is_vpn_gateway_connection",
          "status": "up",
          "status_reasons": [],
          "tunnels": [
            {
              "address": "159.23.99.168",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            },
            {
              "address": "159.23.99.169",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            }
          ]
        },
        {
          "crn": "",
          "gateway_connection": "02h7-0fa9a6fe-39ca-4baa-b7c3-4b2f3fb929e9",
          "id": "02h7-e899e14a-7ef2-4fbf-9f09-210e6a91e0a5/02h7-0fa9a6fe-39ca-4baa-b7c3-4b2f3fb929e9",
          "mode": "route",
          "name": "tr01-to-aws-3",
          "resource_type": "ibm_is_vpn_gateway_connection",
          "status": "up",
          "status_reasons": [],
          "tunnels": [
            {
              "address": "159.23.99.168",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            },
            {
              "address": "159.23.99.169",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            }
          ]
        },
        {
          "crn": "",
          "gateway_connection": "02h7-98e87760-c5d5-4338-a384-cb7e5bae1634",
          "id": "02h7-e899e14a-7ef2-4fbf-9f09-210e6a91e0a5/02h7-98e87760-c5d5-4338-a384-cb7e5bae1634",
          "mode": "route",
          "name": "tr01-to-aws-4",
          "resource_type": "ibm_is_vpn_gateway_connection",
          "status": "up",
          "status_reasons": [],
          "tunnels": [
            {
              "address": "159.23.99.168",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            },
            {
              "address": "159.23.99.169",
              "resource_type": "ibm_is_vpn_gateway_connection_tunnel"
            }
          ]
        }
      ],
      "vpn_gateway": {
        "id": "02h7-e899e14a-7ef2-4fbf-9f09-210e6a91e0a5",
        "name": "tr01-vpn-gw",
        "public_ip_1": "159.23.99.168",
        "public_ip_2": "159.23.99.169",
        "resource_type": "ibm_is_vpn_gateway"
      }
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to IBM VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

> [!NOTE]
> DCS: DevStack Cloud Service
> DevStack company provides OpenStack itself as a service.

### Create AWS to DCS VPN

- API: `POST /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Request:

```json
{
  "vpn_config": {
    "aws": {
      "bgp_asn": "64512",
      "region": "ap-northeast-2",
      "subnet_id": "subnet-081468bee421ca630",
      "vpc_id": "vpc-0436984bd9e51db80"
    },
    "target_csp": {
      "dcs": {
        "bgp_asn": "65000",
        "region": "RegionOne",
        "router_id": "68d569d6-1009-4a9b-b9fa-2ab0d8b45416",
        "subnet_id": "39b13c03-e0ff-4a1b-a51d-03da912fe5fd"
      },
      "type": "dcs"
    },
    "terrarium_id": "tr01"
  }
}
```

- Response

> Omitted the raw response.

### Get the AWS to DCS VPN

- API: `GET /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Query params:
  - detail: refined

- Response:

```json
{
  "success": true,
  "message": "refined read resource info (map)",
  "object": {
    "aws": {
      "customer_gateways": [
        {
          "bgp_asn": "65000",
          "id": "cgw-06a8c8da19046949a",
          "ip_address": "xxx.xxx.xxx.152",
          "name": "tr01-cgw",
          "resource_type": "aws_customer_gateway"
        }
      ],
      "vpn_connections": [
        {
          "id": "vpn-095d49affae7bddb9",
          "name": "tr01-vpn-connection",
          "resource_type": "aws_vpn_connection",
          "tunnel1_address": "3.36.196.64",
          "tunnel2_address": "13.209.78.202"
        }
      ],
      "vpn_gateway": {
        "id": "vgw-005575c7daabedbd3",
        "name": "tr01-vpn-gw",
        "resource_type": "aws_vpn_gateway",
        "vpc_id": "vpc-0436984bd9e51db80"
      }
    },
    "dcs": {
      "site_connections": [
        {
          "id": "c442ac6d-f020-4622-ac3e-c8bf822d657b",
          "name": "tr01-site-connection-1",
          "peer_address": "3.36.196.64",
          "peer_id": "3.36.196.64",
          "resource_type": "openstack_vpnaas_site_connection_v2"
        },
        {
          "id": "f99f3ae7-198d-496a-9fb4-64f1257a365c",
          "name": "tr01-site-connection-2",
          "peer_address": "13.209.78.202",
          "peer_id": "13.209.78.202",
          "resource_type": "openstack_vpnaas_site_connection_v2"
        }
      ],
      "vpn_service": {
        "external_ip": "xxx.xxx.xxx.152",
        "id": "7d74726c-9f87-4b34-80cb-33355e4b2b33",
        "name": "tr01-vpn-service",
        "resource_type": "openstack_vpnaas_service_v2",
        "router_id": "68d569d6-1009-4a9b-b9fa-2ab0d8b45416"
      }
    },
    "terrarium_id": "tr01"
  }
}
```

### Delete the AWS to DCS VPN

- API: `DELETE /tr/{trId}/vpn/aws-to-site`
- Path params:
  - trId: tr01
- Response:

```json
{
  "success": true,
  "message": "successfully emptied out the infrastructure terrarium"
}
```

---

### Delete the terrarium for vpn

- API: `DELETE /tr/{trId}`
- Path params:
  - trId: tr01
- Response

```json
{
  "success": true,
  "message": "successfully erased the entire terrarium (trId: tr01)"
}
```

---

### Delete the testbed

- API: `DELETE /tr/{trId}/testbed`
- Path params:
  - trId: testbed01
- Response

```json
{
  "success": true,
  "message": "successfully destroyed the infrastructure terrarium",
  "details": "Omit this raw data"
}
```

### Delete the terrarium for testbed

- API: `DELETE /tr/{trId}`
- Path params:
  - trId: testbed01
- Response

```json
{
  "success": true,
  "message": "successfully erased the entire terrarium (trId: testbed01)"
}
```
