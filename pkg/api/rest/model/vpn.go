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
