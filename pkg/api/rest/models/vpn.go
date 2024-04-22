package models

type TfVarsGcpAwsVpnTunnel struct {
	ResourceGroupId   string `json:"resource-group-id,omitempty" default:"" example:""`
	AwsRegion         string `json:"aws-region" default:"ap-northeast-2" example:"ap-northeast-2"`
	AwsVpcId          string `json:"aws-vpc-id" example:"vpc-xxxxx"`
	AwsSubnetId       string `json:"aws-subnet-id" example:"subnet-xxxxx"`
	GcpRegion         string `json:"gcp-region" default:"asia-northeast3" example:"asia-northeast3"`
	GcpVpcNetworkName string `json:"gcp-vpc-network-name" default:"tofu-gcp-vpc" example:"tofu-gcp-vpc"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65530"`
}

type TfVarsGcpAzureVpnTunnel struct {
	ResourceGroupId             string `json:"resource-group-id,omitempty" default:"" example:""`
	AzureRegion                 string `json:"azure-region" default:"koreacentral" example:"koreacentral"`
	AzureResourceGroupName      string `json:"azure-resource-group-name" default:"tofu-rg-01" example:"tofu-rg-01"`
	AzureVirtualNetworkName     string `json:"azure-virtual-network-name" default:"tofu-azure-vnet" example:"tofu-azure-vnet"`
	AzureGatewaySubnetCidrBlock string `json:"azure-gateway-subnet-cidr-block" default:"192.168.130.0/24" example:"192.168.130.0/24"`
	GcpRegion                   string `json:"gcp-region" default:"asia-northeast3" example:"asia-northeast3"`
	GcpVpcNetworkName           string `json:"gcp-vpc-network-name" default:"tofu-gcp-vpc" example:"tofu-gcp-vpc"`
	// AzureBgpAsn				 	string `json:"azure-bgp-asn" default:"65515"`
	// GcpBgpAsn                   string `json:"gcp-bgp-asn" default:"65534"`
	// AzureSubnetName             string `json:"azure-subnet-name" default:"tofu-azure-subnet-0"`
	// GcpVpcSubnetworkName    string `json:"gcp-vpc-subnetwork-name" default:"tofu-gcp-subnet-1"`
}
