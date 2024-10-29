package model

type TfVarsGcpAwsVpnTunnel struct {
	TerrariumId       string `json:"terrarium-id,omitempty" default:"" example:""`
	AwsRegion         string `json:"aws-region" default:"ap-northeast-2" example:"ap-northeast-2"`
	AwsVpcId          string `json:"aws-vpc-id" example:"vpc-xxxxx"`
	AwsSubnetId       string `json:"aws-subnet-id" example:"subnet-xxxxx"`
	GcpRegion         string `json:"gcp-region" default:"asia-northeast3" example:"asia-northeast3"`
	GcpVpcNetworkName string `json:"gcp-vpc-network-name" default:"tr-gcp-vpc" example:"tr-gcp-vpc"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65530"`
}

type TfVarsGcpAzureVpnTunnel struct {
	TerrariumId                 string `json:"terrarium-id,omitempty" default:"" example:""`
	AzureRegion                 string `json:"azure-region" default:"koreacentral" example:"koreacentral"`
	AzureResourceGroupName      string `json:"azure-resource-group-name" default:"tr-rg-01" example:"tr-rg-01"`
	AzureVirtualNetworkName     string `json:"azure-virtual-network-name" default:"tr-azure-vnet" example:"tr-azure-vnet"`
	AzureGatewaySubnetCidrBlock string `json:"azure-gateway-subnet-cidr-block" default:"192.168.130.0/24" example:"192.168.130.0/24"`
	GcpRegion                   string `json:"gcp-region" default:"asia-northeast3" example:"asia-northeast3"`
	GcpVpcNetworkName           string `json:"gcp-vpc-network-name" default:"tr-gcp-vpc" example:"tr-gcp-vpc"`
	// AzureBgpAsn				 	string `json:"azure-bgp-asn" default:"65515"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65534"`
	// AzureSubnetName             string `json:"azure-subnet-name" default:"tr-azure-subnet-0"`
	// GcpVpcSubnetworkName    string `json:"gcp-vpc-subnetwork-name" default:"tr-gcp-subnet-1"`
}

type OutputGcpAwsVpnInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	AWS struct {
		VpnGateway struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			VpcID        string `json:"vpc_id"`
		} `json:"vpn_gateway"`
		CustomerGateways []struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			IPAddress    string `json:"ip_address"`
			BgpAsn       string `json:"bgp_asn"`
		} `json:"customer_gateways"`
		VpnConnections []struct {
			ResourceType   string `json:"resource_type"`
			Name           string `json:"name"`
			ID             string `json:"id"`
			Tunnel1Address string `json:"tunnel1_address"`
			Tunnel2Address string `json:"tunnel2_address"`
		} `json:"vpn_connections"`
	} `json:"aws"`
	GCP struct {
		Router struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Network      string `json:"network"`
			BgpAsn       int    `json:"bgp_asn"`
		} `json:"router"`
		HaVpnGateway struct {
			ResourceType string   `json:"resource_type"`
			Name         string   `json:"name"`
			ID           string   `json:"id"`
			Network      string   `json:"network"`
			IPAddresses  []string `json:"ip_addresses"`
		} `json:"ha_vpn_gateway"`
		VpnTunnels []struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			IkeVersion   int    `json:"ike_version"`
			Interface    int    `json:"interface"`
		} `json:"vpn_tunnels"`
	} `json:"gcp"`
}

type OutputGcpAzureVpnInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	Azure struct {
		VirtualNetworkGateway struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Location     string `json:"location"`
			VpnType      string `json:"vpn_type"`
			Sku          string `json:"sku"`
			BgpSettings  struct {
				ASN              int `json:"asn"`
				PeeringAddresses []struct {
					IPAddressConfig string `json:"ip_configuration"`
					Address         string `json:"address"`
				} `json:"peering_addresses"`
			} `json:"bgp_settings"`
		} `json:"virtual_network_gateway"`
		PublicIPs struct {
			IP1 struct {
				ResourceType string `json:"resource_type"`
				Name         string `json:"name"`
				ID           string `json:"id"`
				IPAddress    string `json:"ip_address"`
			} `json:"ip1"`
			IP2 struct {
				ResourceType string `json:"resource_type"`
				Name         string `json:"name"`
				ID           string `json:"id"`
				IPAddress    string `json:"ip_address"`
			} `json:"ip2"`
		} `json:"public_ips"`
		Connections []struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Type         string `json:"type"`
			EnableBgp    bool   `json:"enable_bgp"`
		} `json:"connections"`
	} `json:"azure"`
	GCP struct {
		Router struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Network      string `json:"network"`
			Bgp          struct {
				ASN           int    `json:"asn"`
				AdvertiseMode string `json:"advertise_mode"`
			} `json:"bgp"`
		} `json:"router"`
		HaVpnGateway struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Network      string `json:"network"`
			Interfaces   []struct {
			} `json:"interfaces"`
		} `json:"ha_vpn_gateway"`
		VpnTunnels []struct {
			ResourceType string `json:"resource_type"`
			Name         string `json:"name"`
			ID           string `json:"id"`
			Router       string `json:"router"`
			Interface    int    `json:"interface"`
		} `json:"vpn_tunnels"`
		BgpPeers []struct {
			ResourceType  string `json:"resource_type"`
			Name          string `json:"name"`
			PeerIP        string `json:"peer_ip"`
			PeerASN       int    `json:"peer_asn"`
			InterfaceName string `json:"interface_name"`
		} `json:"bgp_peers"`
	} `json:"gcp"`
}
