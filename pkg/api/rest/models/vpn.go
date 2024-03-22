package models

type TfVarsGcpAwsVpnTunnel struct {
	MyImportedAWSVPCId      string `json:"my-imported-aws-vpc-id" default:""`
	MyImportedAWSSubnetId   string `json:"my-imported-aws-subnet-id" default:""`
	MyImportedGCPVPCName    string `json:"my-imported-gcp-vpc-name" default:""`
	MyImportedGCPSubnetName string `json:"my-imported-gcp-subnet-name" default:""`
}

type TfVarsGcpAzureVpnTunnel struct {
	AzureRegion             string `json:"azure-region" default:"koreacentral"`
	AzureResourceGroupName  string `json:"azure-resource-group-name" default:"tofu-rg-01"`
	AzureVirtualNetworkName string `json:"azure-virtual-network-name" default:"tofu-azure-vnet"`
	AzureSubnetName         string `json:"azure-subnet-name" default:"tofu-azure-subnet-0"`
	AzureGatewaySubnetName  string `json:"azure-gateway-subnet-name" default:"GatewaySubnet"`
	GcpRegion               string `json:"gcp-region" default:"asia-northeast3"`
	GcpVpcNetworkName       string `json:"gcp-vpc-network-name" default:"tofu-gcp-vpc"`
	GcpVpcSubnetworkName    string `json:"gcp-vpc-subnetwork-name" default:"tofu-gcp-subnet-1"`
}
