package model

// TfVarsObjectStorage represents the configuration structure based on the Terraform variables
type TfVarsObjectStorage struct {
	TerrariumID      string `json:"terrarium_id" default:"" example:""`
	CSPRegion        string `json:"csp_region" example:"ap-northeast-2"`
	CSPResourceGroup string `json:"csp_resource_group,omitempty" example:"koreacentral"`
}

type ObjectStorageInfo struct {
	Terrarium           TerrariumInfo       `json:"terrarium"`
	ObjectStorageDetail ObjectStorageDetail `json:"object_storage_detail"`
}

type ObjectStorageDetail struct {
	// Basic Information
	StorageName string            `json:"storage_name"`
	Location    string            `json:"location"`
	Tags        map[string]string `json:"tags"`

	// Access Configuration
	PublicAccessEnabled bool   `json:"public_access_enabled"`
	HTTPSOnly           bool   `json:"https_only"`
	PrimaryEndpoint     string `json:"primary_endpoint"`

	// Provider Specific Details
	ProviderSpecificDetail interface{} `json:"provider_specific_detail"`
}

// AWS specific structures
type AWSProviderSpecificDetail struct {
	Provider           string                `json:"provider"` // "aws"
	BucketName         string                `json:"bucket_name"`
	BucketARN          string                `json:"bucket_arn"`
	BucketRegion       string                `json:"bucket_region"`
	RegionalDomainName string                `json:"regional_domain_name"`
	VersioningEnabled  bool                  `json:"versioning_enabled"`
	PublicAccessConfig AWSPublicAccessConfig `json:"public_access_config"`
}

type AWSPublicAccessConfig struct {
	BlockPublicACLs       bool `json:"block_public_acls"`
	BlockPublicPolicy     bool `json:"block_public_policy"`
	IgnorePublicACLs      bool `json:"ignore_public_acls"`
	RestrictPublicBuckets bool `json:"restrict_public_buckets"`
}

// Azure specific structures
type AzureProviderSpecificDetail struct {
	Provider           string            `json:"provider"` // "azure"
	StorageAccountName string            `json:"storage_account_name"`
	ResourceGroup      string            `json:"resource_group"`
	AccountTier        string            `json:"account_tier"`
	ReplicationType    string            `json:"replication_type"`
	AccessTier         string            `json:"access_tier"`
	Endpoints          AzureEndpoints    `json:"endpoints"`
	NetworkRules       AzureNetworkRules `json:"network_rules"`
}

type AzureEndpoints struct {
	Blob     string `json:"blob"`
	BlobHost string `json:"blob_host"`
	DFS      string `json:"dfs"`
	Web      string `json:"web"`
}

type AzureNetworkRules struct {
	DefaultAction string   `json:"default_action"`
	Bypass        []string `json:"bypass"`
}
