package model

import (
	"errors"
	"fmt"
	"net"
	"regexp"
	"strings"
)

/*
 * Input/request body for the site to site VPN configuration
 */

// SiteToSiteVpnConfig represents the main VPN configuration structure
type SiteToSiteVpnConfig struct {
	TerrariumId string         `json:"terrarium_id"`
	Alibaba     *AlibabaConfig `json:"alibaba,omitempty"`
	Aws         *AwsConfig     `json:"aws,omitempty"`
	Azure       *AzureConfig   `json:"azure,omitempty"`
	Gcp         *GcpConfig     `json:"gcp,omitempty"`
	Ibm         *IbmConfig     `json:"ibm,omitempty"`
	Tencent     *TencentConfig `json:"tencent,omitempty"`
}

// GcpConfig represents GCP specific VPN configuration
type GcpConfig struct {
	Region         string `json:"region,omitempty" default:"asia-northeast3" example:"asia-northeast3"`
	VpcNetworkName string `json:"vpc_network_name"`
	BgpAsn         string `json:"bgp_asn,omitempty" default:"65530" example:"65530"`
}

// AzureConfig represents Azure specific VPN configuration
type AzureConfig struct {
	Region             string `json:"region"`
	ResourceGroupName  string `json:"resource_group_name"`
	VirtualNetworkName string `json:"virtual_network_name"`
	GatewaySubnetCidr  string `json:"gateway_subnet_cidr"`
	BgpAsn             string `json:"bgp_asn,omitempty" default:"65531" example:"65531"`
	VpnSku             string `json:"vpn_sku,omitempty" default:"VpnGw1AZ" example:"VpnGw1AZ"`
}

// AlibabaConfig represents Alibaba Cloud specific VPN configuration
type AlibabaConfig struct {
	Region     string `json:"region,omitempty" default:"ap-northeast-2" example:"ap-northeast-2"`
	VpcId      string `json:"vpc_id"`
	VswitchId1 string `json:"vswitch_id_1"`
	VswitchId2 string `json:"vswitch_id_2"`
	BgpAsn     string `json:"bgp_asn,omitempty" default:"65532" example:"65532"`
}

// TencentConfig represents Tencent Cloud specific VPN configuration
// Currently commented out in the original definition
type TencentConfig struct {
	Region   string `json:"region" default:"ap-seoul" example:"ap-seoul"`
	VpcId    string `json:"vpc_id"`
	SubnetId string `json:"subnet_id"`
	// BgpAsn   *string `json:"bgp_asn" default:"65534" example:"65534"`
}

// IbmConfig represents IBM Cloud specific VPN configuration
type IbmConfig struct {
	Region   string `json:"region,omitempty" default:"au-syd" example:"au-syd"`
	VpcId    string `json:"vpc_id"`
	VpcCidr  string `json:"vpc_cidr"`
	SubnetId string `json:"subnet_id"`
	// BgpAsn    *string `json:"bgp_asn,omitempty" default:"65533" example:"65533"`
}

// AwsConfig represents AWS specific VPN configuration
type AwsConfig struct {
	Region   string `json:"region,omitempty" default:"ap-northeast-2" example:"ap-northeast-2"`
	VpcId    string `json:"vpc_id"`
	SubnetId string `json:"subnet_id"`
	BgpAsn   string `json:"bgp_asn,omitempty" default:"64512" example:"64512"`
}

// Validate validates the VpnConfig structure
func (v *SiteToSiteVpnConfig) Validate() error {
	if v == nil {
		return errors.New("vpn config cannot be nil")
	}

	// Validate terrarium ID
	if err := v.validateTerrariumId(); err != nil {
		return err
	}

	// Count enabled CSPs and validate each
	enabledCount := 0
	var validationErrors []string

	if v.Aws != nil {
		enabledCount++
		if err := v.Aws.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("AWS config: %v", err))
		}
	}

	if v.Gcp != nil {
		enabledCount++
		if err := v.Gcp.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("GCP config: %v", err))
		}
	}

	if v.Azure != nil {
		enabledCount++
		if err := v.Azure.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("Azure config: %v", err))
		}
	}

	if v.Alibaba != nil {
		enabledCount++
		if err := v.Alibaba.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("Alibaba config: %v", err))
		}
	}

	if v.Tencent != nil {
		enabledCount++
		if err := v.Tencent.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("Tencent config: %v", err))
		}
	}

	if v.Ibm != nil {
		enabledCount++
		if err := v.Ibm.Validate(); err != nil {
			validationErrors = append(validationErrors, fmt.Sprintf("IBM config: %v", err))
		}
	}

	// Check minimum CSP requirement
	if enabledCount != 2 {
		validationErrors = append(validationErrors, "site-to-site VPN requires exactly 2 CSP configurations")
	}

	if len(validationErrors) > 0 {
		return fmt.Errorf("validation failed: %s", strings.Join(validationErrors, "; "))
	}

	return nil
}

// validateTerrariumId validates the terrarium ID
func (v *SiteToSiteVpnConfig) validateTerrariumId() error {
	if v.TerrariumId == "" {
		return errors.New("terrarium_id is required")
	}

	// Check length
	if len(v.TerrariumId) < 3 || len(v.TerrariumId) > 50 {
		return errors.New("terrarium_id must be between 3 and 50 characters")
	}

	// Check format (alphanumeric, hyphens, underscores only)
	matched, _ := regexp.MatchString("^[a-zA-Z0-9_-]+$", v.TerrariumId)
	if !matched {
		return errors.New("terrarium_id can only contain alphanumeric characters, hyphens, and underscores")
	}

	return nil
}

// GetEnabledCSPs returns a list of enabled CSP names
func (v *SiteToSiteVpnConfig) GetEnabledCSPs() []string {
	var csps []string

	if v.Aws != nil {
		csps = append(csps, "aws")
	}
	if v.Gcp != nil {
		csps = append(csps, "gcp")
	}
	if v.Azure != nil {
		csps = append(csps, "azure")
	}
	if v.Alibaba != nil {
		csps = append(csps, "alibaba")
	}
	if v.Tencent != nil {
		csps = append(csps, "tencent")
	}
	if v.Ibm != nil {
		csps = append(csps, "ibm")
	}

	return csps
}

// Validate AWS configuration
func (a *AwsConfig) Validate() error {
	if a == nil {
		return errors.New("aws config cannot be nil")
	}

	var errors []string

	// Validate VPC ID
	if a.VpcId == "" {
		errors = append(errors, "vpc_id is required")
	} else if !regexp.MustCompile(`^vpc-[0-9a-f]{8,17}$`).MatchString(a.VpcId) {
		errors = append(errors, "vpc_id must be in format vpc-xxxxxxxx")
	}

	// Validate Subnet ID
	if a.SubnetId == "" {
		errors = append(errors, "subnet_id is required")
	} else if !regexp.MustCompile(`^subnet-[0-9a-f]{8,17}$`).MatchString(a.SubnetId) {
		errors = append(errors, "subnet_id must be in format subnet-xxxxxxxx")
	}

	// Validate BGP ASN (optional)
	if a.BgpAsn != "" {
		if err := validateBgpAsn(a.BgpAsn); err != nil {
			errors = append(errors, fmt.Sprintf("bgp_asn: %v", err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Validate GCP configuration
func (g *GcpConfig) Validate() error {
	if g == nil {
		return errors.New("gcp config cannot be nil")
	}

	var errors []string

	// Validate VPC Network Name
	if g.VpcNetworkName == "" {
		errors = append(errors, "vpc_network_name is required")
	} else if !regexp.MustCompile(`^[a-z]([-a-z0-9]*[a-z0-9])?$`).MatchString(g.VpcNetworkName) {
		errors = append(errors, "vpc_network_name must follow GCP naming conventions")
	}

	// Validate BGP ASN (optional)
	if g.BgpAsn != "" {
		if err := validateBgpAsn(g.BgpAsn); err != nil {
			errors = append(errors, fmt.Sprintf("bgp_asn: %v", err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Validate Azure configuration
func (a *AzureConfig) Validate() error {
	if a == nil {
		return errors.New("azure config cannot be nil")
	}

	var errors []string

	// Validate Region
	if a.Region == "" {
		errors = append(errors, "region is required")
	}

	// Validate Resource Group Name
	if a.ResourceGroupName == "" {
		errors = append(errors, "resource_group_name is required")
	} else if len(a.ResourceGroupName) > 90 {
		errors = append(errors, "resource_group_name cannot exceed 90 characters")
	}

	// Validate Virtual Network Name
	if a.VirtualNetworkName == "" {
		errors = append(errors, "virtual_network_name is required")
	}

	// Validate Gateway Subnet CIDR
	if a.GatewaySubnetCidr == "" {
		errors = append(errors, "gateway_subnet_cidr is required")
	} else {
		if _, _, err := net.ParseCIDR(a.GatewaySubnetCidr); err != nil {
			errors = append(errors, "gateway_subnet_cidr must be a valid CIDR notation")
		}
	}

	// Validate VPN SKU (optional)
	if a.VpnSku != "" {
		validSkus := []string{"VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"}
		if !contains(validSkus, a.VpnSku) {
			errors = append(errors, "vpn_sku must be one of: "+strings.Join(validSkus, ", "))
		}
	}

	// Validate BGP ASN (optional)
	if a.BgpAsn != "" {
		if err := validateBgpAsn(a.BgpAsn); err != nil {
			errors = append(errors, fmt.Sprintf("bgp_asn: %v", err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Validate Alibaba configuration
func (a *AlibabaConfig) Validate() error {
	if a == nil {
		return errors.New("alibaba config cannot be nil")
	}

	var errors []string

	// Validate VPC ID
	if a.VpcId == "" {
		errors = append(errors, "vpc_id is required")
	}

	// Validate VSwitch IDs
	if a.VswitchId1 == "" {
		errors = append(errors, "vswitch_id_1 is required")
	}
	if a.VswitchId2 == "" {
		errors = append(errors, "vswitch_id_2 is required")
	}

	// Validate BGP ASN (optional)
	if a.BgpAsn != "" {
		if err := validateBgpAsn(a.BgpAsn); err != nil {
			errors = append(errors, fmt.Sprintf("bgp_asn: %v", err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Validate Tencent configuration
func (t *TencentConfig) Validate() error {
	if t == nil {
		return errors.New("tencent config cannot be nil")
	}

	var errors []string

	// Validate VPC ID
	if t.VpcId == "" {
		errors = append(errors, "vpc_id is required")
	}

	// Validate Subnet ID
	if t.SubnetId == "" {
		errors = append(errors, "subnet_id is required")
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Validate IBM configuration
func (i *IbmConfig) Validate() error {
	if i == nil {
		return errors.New("ibm config cannot be nil")
	}

	var errors []string

	// Validate VPC ID
	if i.VpcId == "" {
		errors = append(errors, "vpc_id is required")
	}

	// Validate VPC CIDR
	if i.VpcCidr == "" {
		errors = append(errors, "vpc_cidr is required")
	} else {
		if _, _, err := net.ParseCIDR(i.VpcCidr); err != nil {
			errors = append(errors, "vpc_cidr must be a valid CIDR notation")
		}
	}

	// Validate Subnet ID
	if i.SubnetId == "" {
		errors = append(errors, "subnet_id is required")
	}

	if len(errors) > 0 {
		return fmt.Errorf(strings.Join(errors, "; "))
	}

	return nil
}

// Helper function to validate BGP ASN
func validateBgpAsn(asn string) error {
	if asn == "" {
		return nil // Optional field
	}

	// BGP ASN should be a number between 1 and 4294967295
	matched, _ := regexp.MatchString(`^[0-9]+$`, asn)
	if !matched {
		return errors.New("must be a numeric value")
	}

	// Additional range validation could be added here
	return nil
}

// Helper function to check if slice contains string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
