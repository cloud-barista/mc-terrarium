package model

// TfVarsMessageBroker represents the configuration structure based on the Terraform variables
type TfVarsMessageBroker struct {
	TerrariumID string `json:"terrarium_id" default:"" example:""`
	CSPRegion   string `json:"csp_region" example:"ap-northeast-2"`
	CSPVNetID   string `json:"csp_vnet_id,omitempty" example:"vpc-12345678"`
	// CSPResourceGroup string `json:"csp_resource_group,omitempty" example:"koreacentral"`
}

// OutputMessageBrokerInfo represents the Message Broker information structure
type OutputMessageBrokerInfo struct {
	Terrarium           TerrariumInfo       `json:"terrarium"`
	MessageBrokerDetail MessageBrokerDetail `json:"message_broker_detail"`
}

type MessageBrokerDetail struct {
	// Basic Information
	BrokerName       string `json:"broker_name"`
	BrokerID         string `json:"broker_id"`
	EngineType       string `json:"engine_type"`
	EngineVersion    string `json:"engine_version"`
	HostInstanceType string `json:"host_instance_type"`
	DeploymentMode   string `json:"deployment_mode"`

	// Connection Details
	BrokerEndpoint     string `json:"broker_endpoint"`
	PubliclyAccessible bool   `json:"publicly_accessible"`

	// Authentication
	Username string `json:"username"`

	// Provider Specific Details
	ProviderSpecificDetail ProviderSpecificMessageBrokerDetail `json:"provider_specific_detail"`
}

type ProviderSpecificMessageBrokerDetail struct {
	Provider           string   `json:"provider"`
	Region             string   `json:"region"`
	ResourceIdentifier string   `json:"resource_identifier"`
	SecurityGroupIDs   []string `json:"security_group_ids"`
	SubnetIDs          []string `json:"subnet_ids"`
	StorageType        string   `json:"storage_type"`
}
