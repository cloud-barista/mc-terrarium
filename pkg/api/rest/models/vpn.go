package models

type TfVarsGcpAwsVpnTunnel struct {
	AwsRegion         string `json:"aws-region" default:"ap-northeast-2"`
	AwsVpcId          string `json:"aws-vpc-id" default:""`
	AwsSubnetId       string `json:"aws-subnet-id" default:""`
	GcpRegion         string `json:"gcp-region" default:"asia-northeast3"`
	GcpVpcNetworkName string `json:"gcp-vpc-network-name" default:"tofu-gcp-vpc"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65530"`
}

type TfVarsGcpAzureVpnTunnel struct {
	AzureRegion                 string `json:"azure-region" default:"koreacentral"`
	AzureResourceGroupName      string `json:"azure-resource-group-name" default:"tofu-rg-01"`
	AzureVirtualNetworkName     string `json:"azure-virtual-network-name" default:"tofu-azure-vnet"`
	AzureGatewaySubnetCidrBlock string `json:"azure-gateway-subnet-cidr-block" default:"192.168.130.0/24"`
	GcpRegion                   string `json:"gcp-region" default:"asia-northeast3"`
	GcpVpcNetworkName           string `json:"gcp-vpc-network-name" default:"tofu-gcp-vpc"`
	// AzureBgpAsn				 	string `json:"azure-bgp-asn" default:"65515"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65534"`
	// AzureSubnetName             string `json:"azure-subnet-name" default:"tofu-azure-subnet-0"`
	// GcpVpcSubnetworkName    string `json:"gcp-vpc-subnetwork-name" default:"tofu-gcp-subnet-1"`
}
