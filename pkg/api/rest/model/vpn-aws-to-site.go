package model

import "fmt"

/*
 * Model for the AWS to site VPN configuration
 */

// GcpConfig represents GCP specific VPN configuration
type GcpConfig struct {
	Region         *string `json:"region,omitempty" default:"asia-northeast3" example:"asia-northeast3"`
	VpcNetworkName string  `json:"vpc_network_name"`
	BgpAsn         *string `json:"bgp_asn,omitempty" default:"65530" example:"65530"`
}

// AzureConfig represents Azure specific VPN configuration
type AzureConfig struct {
	Region              string  `json:"region"`
	ResourceGroupName   string  `json:"resource_group_name"`
	VirtualNetworkName  string  `json:"virtual_network_name"`
	GatewaySubnetCidr   string  `json:"gateway_subnet_cidr"`
	BgpAsn              *string `json:"bgp_asn,omitempty" default:"65531" example:"65531"`
	VpnSku              *string `json:"vpn_sku,omitempty" default:"VpnGw1AZ" example:"VpnGw1AZ"`
}

// AlibabaConfig represents Alibaba Cloud specific VPN configuration
type AlibabaConfig struct {
	Region      *string `json:"region,omitempty" default:"ap-northeast-2" example:"ap-northeast-2"`
	VpcId       string  `json:"vpc_id"`
	VswitchId1  string  `json:"vswitch_id_1"`
	VswitchId2  string  `json:"vswitch_id_2"`
	BgpAsn      *string `json:"bgp_asn,omitempty" default:"65532" example:"65532"`
}

// IbmConfig represents IBM Cloud specific VPN configuration
type IbmConfig struct {
	Region    *string `json:"region,omitempty" default:"au-syd" example:"au-syd"`
	VpcId     string  `json:"vpc_id"`
	VpcCidr   string  `json:"vpc_cidr"`
	SubnetId  string  `json:"subnet_id"`
	BgpAsn    *string `json:"bgp_asn,omitempty" default:"65533" example:"65533"`
}

// TencentConfig represents Tencent Cloud specific VPN configuration
// Currently commented out in the original definition
type TencentConfig struct {
	Region   string `json:"region" default:"ap-seoul" example:"ap-seoul"`
	VpcId    string `json:"vpc_id"`
	SubnetId string `json:"subnet_id"`
	BgpAsn   string `json:"bgp_asn" default:"65534" example:"65534"`
}

// AwsConfig represents AWS specific VPN configuration
type AwsConfig struct {
	Region    *string `json:"region,omitempty" default:"ap-northeast-2" example:"ap-northeast-2"`
	VpcId     string  `json:"vpc_id"`
	SubnetId  string  `json:"subnet_id"`
}

// TargetCspConfig represents the target cloud service provider configuration
type TargetCspConfig struct {
	Type     string         `json:"type"`
	Gcp      *GcpConfig     `json:"gcp,omitempty"`
	Azure    *AzureConfig   `json:"azure,omitempty"`
	Alibaba  *AlibabaConfig `json:"alibaba,omitempty"`
	Ibm      *IbmConfig     `json:"ibm,omitempty"`
	Tencent  *TencentConfig `json:"tencent,omitempty"`
}

// AwsToSiteVpnConfig represents the main VPN configuration structure
type AwsToSiteVpnConfig struct {
	TerrariumId string         `json:"terrarium_id"`
	Aws         AwsConfig      `json:"aws"`
	TargetCsp   TargetCspConfig `json:"target_csp"`
}

// Validate validates the AWS to Site VPN configuration
func (config *AwsToSiteVpnConfig) Validate() error {
	// Validate TerrariumId
	if config.TerrariumId == "" {
		return fmt.Errorf("terrarium_id is required")
	}

	// Validate AWS configuration
	if err := validateAwsConfig(config.Aws); err != nil {
		return err
	}

	// Validate TargetCsp
	if err := validateTargetCspConfig(config.TargetCsp); err != nil {
		return err
	}

	return nil
}

// validateAwsConfig validates AWS configuration
func validateAwsConfig(aws AwsConfig) error {
	// Check required AWS fields
	if aws.VpcId == "" {
		return fmt.Errorf("aws.vpc_id is required")
	}
	if aws.SubnetId == "" {
		return fmt.Errorf("aws.subnet_id is required")
	}

	return nil
}

// validateTargetCspConfig validates target CSP configuration
func validateTargetCspConfig(targetCsp TargetCspConfig) error {
	// Validate CSP type
	validTypes := map[string]bool{
		"gcp":     true,
		"azure":   true,
		"alibaba": true,
		"ibm":     true,
		"tencent": true,
	}

	if !validTypes[targetCsp.Type] {
		return fmt.Errorf("invalid target_csp.type: %s. Must be one of: gcp, azure, alibaba, ibm, tencent", targetCsp.Type)
	}

	// Validate that the corresponding CSP configuration is provided
	switch targetCsp.Type {
	case "gcp":
		if targetCsp.Gcp == nil {
			return fmt.Errorf("gcp configuration is required when target_csp.type is 'gcp'")
		}
		if err := validateGcpConfig(*targetCsp.Gcp); err != nil {
			return err
		}
	case "azure":
		if targetCsp.Azure == nil {
			return fmt.Errorf("azure configuration is required when target_csp.type is 'azure'")
		}
		if err := validateAzureConfig(*targetCsp.Azure); err != nil {
			return err
		}
	case "alibaba":
		if targetCsp.Alibaba == nil {
			return fmt.Errorf("alibaba configuration is required when target_csp.type is 'alibaba'")
		}
		if err := validateAlibabaConfig(*targetCsp.Alibaba); err != nil {
			return err
		}
	case "ibm":
		if targetCsp.Ibm == nil {
			return fmt.Errorf("ibm configuration is required when target_csp.type is 'ibm'")
		}
		if err := validateIbmConfig(*targetCsp.Ibm); err != nil {
			return err
		}
	case "tencent":
		if targetCsp.Tencent == nil {
			return fmt.Errorf("tencent configuration is required when target_csp.type is 'tencent'")
		}
		if err := validateTencentConfig(*targetCsp.Tencent); err != nil {
			return err
		}
	}

	return nil
}

// validateGcpConfig validates GCP configuration
func validateGcpConfig(gcp GcpConfig) error {
	if gcp.VpcNetworkName == "" {
		return fmt.Errorf("gcp.vpc_network_name is required")
	}
	return nil
}

// validateAzureConfig validates Azure configuration
func validateAzureConfig(azure AzureConfig) error {
	if azure.Region == "" {
		return fmt.Errorf("azure.region is required")
	}
	if azure.ResourceGroupName == "" {
		return fmt.Errorf("azure.resource_group_name is required")
	}
	if azure.VirtualNetworkName == "" {
		return fmt.Errorf("azure.virtual_network_name is required")
	}
	if azure.GatewaySubnetCidr == "" {
		return fmt.Errorf("azure.gateway_subnet_cidr is required")
	}
	return nil
}

// validateAlibabaConfig validates Alibaba Cloud configuration
func validateAlibabaConfig(alibaba AlibabaConfig) error {
	if alibaba.VpcId == "" {
		return fmt.Errorf("alibaba.vpc_id is required")
	}
	if alibaba.VswitchId1 == "" {
		return fmt.Errorf("alibaba.vswitch_id_1 is required")
	}
	if alibaba.VswitchId2 == "" {
		return fmt.Errorf("alibaba.vswitch_id_2 is required")
	}
	return nil
}

// validateIbmConfig validates IBM Cloud configuration
func validateIbmConfig(ibm IbmConfig) error {
	if ibm.VpcId == "" {
		return fmt.Errorf("ibm.vpc_id is required")
	}
	if ibm.VpcCidr == "" {
		return fmt.Errorf("ibm.vpc_cidr is required")
	}
	if ibm.SubnetId == "" {
		return fmt.Errorf("ibm.subnet_id is required")
	}
	return nil
}

// validateTencentConfig validates Tencent Cloud configuration
func validateTencentConfig(tencent TencentConfig) error {
	if tencent.Region == "" {
		return fmt.Errorf("tencent.region is required")
	}
	if tencent.VpcId == "" {
		return fmt.Errorf("tencent.vpc_id is required")
	}
	if tencent.BgpAsn == "" {
		return fmt.Errorf("tencent.bgp_asn is required")
	}
	return nil
}



/*
 * Model for the AWS to site VPN information
 */

// AwsVpnGateway represents AWS VPN gateway information
type AwsVpnGateway struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	VpcID        string `json:"vpc_id"`
}

// AwsCustomerGateway represents AWS customer gateway information
type AwsCustomerGateway struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	IPAddress    string `json:"ip_address"`
	BgpAsn       string `json:"bgp_asn"`
}

// AwsVpnConnection represents AWS VPN connection information
type AwsVpnConnection struct {
	ResourceType   string `json:"resource_type"`
	Name           string `json:"name"`
	ID             string `json:"id"`
	Tunnel1Address string `json:"tunnel1_address"`
	Tunnel2Address string `json:"tunnel2_address"`
}

// AwsInfo represents AWS-specific VPN information
type AwsInfo struct {
	VpnGateway       AwsVpnGateway        `json:"vpn_gateway"`
	CustomerGateways []AwsCustomerGateway `json:"customer_gateways"`
	VpnConnections   []AwsVpnConnection   `json:"vpn_connections"`
}

// GcpVpnGateway represents GCP VPN gateway information
type GcpVpnGateway struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	Network      string `json:"network"`
	Region       string `json:"region"`
}

// GcpExternalGatewayInterface represents interface for GCP external gateway
type GcpExternalGatewayInterface struct {
	ID        string `json:"id"`
	IPAddress string `json:"ip_address"`
}

// GcpExternalGateway represents GCP external gateway information
type GcpExternalGateway struct {
	ResourceType   string                      `json:"resource_type"`
	Name           string                      `json:"name"`
	ID             string                      `json:"id"`
	RedundancyType string                      `json:"redundancy_type"`
	Description    string                      `json:"description"`
	Interfaces     []GcpExternalGatewayInterface `json:"interfaces"`
}

// GcpRouter represents GCP router information
type GcpRouter struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	Network      string `json:"network"`
	BgpAsn       string `json:"bgp_asn"`
}

// GcpTunnel represents GCP tunnel information
type GcpTunnel struct {
	Name      string `json:"name"`
	ID        string `json:"id"`
	PeerIP    string `json:"peer_ip"`
	Interface int    `json:"interface"`
}

// GcpInterface represents GCP interface information
type GcpInterface struct {
	Name    string `json:"name"`
	ID      string `json:"id"`
	IPRange string `json:"ip_range"`
}

// GcpPeer represents GCP peer information
type GcpPeer struct {
	Name    string `json:"name"`
	ID      string `json:"id"`
	PeerIP  string `json:"peer_ip"`
	PeerAsn string `json:"peer_asn"`
}

// GcpInfo represents GCP-specific target CSP information
type GcpInfo struct {
	VpnGateway      GcpVpnGateway     `json:"vpn_gateway"`
	ExternalGateway GcpExternalGateway `json:"external_gateway"`
	Router          GcpRouter         `json:"router"`
	Tunnels         []GcpTunnel       `json:"tunnels"`
	Interfaces      []GcpInterface    `json:"interfaces"`
	Peers           []GcpPeer         `json:"peers"`
}

// AzureVpnGateway represents Azure VPN gateway information
type AzureVpnGateway struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	Location     string `json:"location"`
	Sku          string `json:"sku"`
}

// AzurePublicIP represents Azure public IP information
type AzurePublicIP struct {
	Name      string `json:"name"`
	ID        string `json:"id"`
	IPAddress string `json:"ip_address"`
}

// AzureConnection represents Azure connection information
type AzureConnection struct {
	Name      string `json:"name"`
	ID        string `json:"id"`
	Type      string `json:"type"`
	EnableBgp bool   `json:"enable_bgp"`
}

// AzureLocalGateway represents Azure local gateway information
type AzureLocalGateway struct {
	Name           string `json:"name"`
	ID             string `json:"id"`
	GatewayAddress string `json:"gateway_address"`
}

// AzureInfo represents Azure-specific target CSP information
type AzureInfo struct {
	VpnGateway    *AzureVpnGateway    `json:"vpn_gateway,omitempty"`
	PublicIPs     []AzurePublicIP     `json:"public_ips"`
	Connections   []AzureConnection   `json:"connections"`
	LocalGateways []AzureLocalGateway `json:"local_gateways"`
}

// AlibabaVpnGateway represents Alibaba Cloud VPN gateway information
type AlibabaVpnGateway struct {
	ID                         string `json:"id"`
	InternetIP                 string `json:"internet_ip"`
	DisasterRecoveryInternetIP string `json:"disaster_recovery_internet_ip"`
}

// AlibabaCustomerGateway represents Alibaba Cloud customer gateway information
type AlibabaCustomerGateway struct {
	ID        string `json:"id"`
	IPAddress string `json:"ip_address"`
	Asn       string `json:"asn"`
}

// AlibabaTunnelOption represents Alibaba Cloud tunnel option information
type AlibabaTunnelOption struct {
	ID         string `json:"id"`
	State      string `json:"state"`
	Status     string `json:"status"`
	BgpStatus  string `json:"bsp_status"`
	PeerAsn    string `json:"peer_asn"`
	PeerBgpIP  string `json:"peer_bgp_ip"`
}

// AlibabaVpnConnection represents Alibaba Cloud VPN connection information
type AlibabaVpnConnection struct {
	ID        string              `json:"id"`
	BgpStatus string              `json:"bgp_status"`
	Tunnels   []AlibabaTunnelOption `json:"tunnels"`
}

// AlibabaInfo represents Alibaba Cloud-specific target CSP information
type AlibabaInfo struct {
	VpnGateway      *AlibabaVpnGateway      `json:"vpn_gateway,omitempty"`
	CustomerGateways []AlibabaCustomerGateway `json:"customer_gateways"`
	VpnConnections  []AlibabaVpnConnection  `json:"vpn_connections"`
}

// IbmVpnGateway represents IBM Cloud VPN gateway information
type IbmVpnGateway struct {
	ResourceType string `json:"resource_type"`
	Name         string `json:"name"`
	ID           string `json:"id"`
	PublicIP1    string `json:"public_ip_1"`
	PublicIP2    string `json:"public_ip_2"`
}

// IbmVpnConnection represents IBM Cloud VPN connection information
type IbmVpnConnection struct {
	Name         string   `json:"name"`
	ID           string   `json:"id"`
	PresharedKey string   `json:"preshared_key"`
	LocalCidrs   []string `json:"local_cidrs"`
	PeerAddress  string   `json:"peer_address"`
	PeerCidrs    []string `json:"peer_cidrs"`
}

// IbmInfo represents IBM Cloud-specific target CSP information
type IbmInfo struct {
	VpnGateway     *IbmVpnGateway     `json:"vpn_gateway,omitempty"`
	VpnConnections []IbmVpnConnection `json:"vpn_connections"`
}

// TargetCspInfo represents target CSP information with all possible CSP types
type TargetCspInfo struct {
	Type    string      `json:"type"`
	Gcp     *GcpInfo    `json:"gcp,omitempty"`
	Azure   *AzureInfo  `json:"azure,omitempty"`
	Alibaba *AlibabaInfo `json:"alibaba,omitempty"`
	Ibm     *IbmInfo    `json:"ibm,omitempty"`
}

// VpnInfo represents the main VPN information output structure
type VpnInfo struct {
	Terrarium TerrariumInfo `json:"terrarium"`
	Aws       AwsInfo       `json:"aws"`
	TargetCsp TargetCspInfo `json:"target_csp"`
}