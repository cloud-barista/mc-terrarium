package model

// TfVarsSqlDb represents the configuration structure based on the Terraform variables
type TfVarsSqlDb struct {
	TerrariumID      string `json:"terrarium_id" default:"" example:""`
	CSPRegion        string `json:"csp_region" example:"ap-northeast-2"`
	CSPResourceGroup string `json:"csp_resource_group,omitempty" example:"rg-12345678"`
	CSPVNetID        string `json:"csp_vnet_id,omitempty" example:"vpc-12345678"`
	CSPSubnet1ID     string `json:"csp_subnet1_id,omitempty" example:"subnet-1234abcd"`
	CSPSubnet2ID     string `json:"csp_subnet2_id,omitempty" example:"subnet-abcd1234"`
	DBEnginePort     int    `json:"db_engine_port,omitempty" example:"3306"`
	IngressCIDRBlock string `json:"ingress_cidr_block,omitempty" example:"0.0.0.0/0"`
	EgressCIDRBlock  string `json:"egress_cidr_block,omitempty" example:"0.0.0.0/0"`
	DBEngineVersion  string `json:"db_engine_version,omitempty" example:"8.0.39"`
	DBInstanceSpec   string `json:"db_instance_spec,omitempty" example:"db.t3.micro"`
	DBAdminUsername  string `json:"db_admin_username" example:"mydbadmin"`
	DBAdminPassword  string `json:"db_admin_password" example:"Password1234!"`
	// DBInstanceID     string `json:"db_instance_identifier" example:"mydbinstance"`
}

// OutputSQLDBInfo represents the SQL Database information structure
type OutputSQLDBInfo struct {
	Terrarium   Terrarium   `json:"terrarium"`
	SQLDBDetail SqlDbDetail `json:"sql_db_detail"`
}

type Terrarium struct {
	ID string `json:"id"`
}

type SqlDbDetail struct {
	// Basic Information
	InstanceName       string            `json:"instance_name"`
	InstanceResourceID string            `json:"instance_resource_id"`
	InstanceSpec       string            `json:"instance_spec"`
	Location           string            `json:"location"`
	Tags               map[string]string `json:"tags,omitempty"`

	// Storage Configuration
	StorageType string `json:"storage_type"`
	StorageSize int    `json:"storage_size"` // GB

	// Database Engine Information
	EngineName    string `json:"engine_name"`
	EngineVersion string `json:"engine_version"`

	// Database Connection Details
	ConnectionEndpoint  string `json:"connection_endpoint"`
	ConnectionHost      string `json:"connection_host"`
	ConnectionPort      int    `json:"connection_port"`
	PublicAccessEnabled bool   `json:"public_access_enabled"`

	// Authentication
	AdminUsername string `json:"admin_username"`

	// Provider Specific Details
	ProviderSpecificDetail ProviderSpecificSqlDbDetail `json:"provider_specific_detail"`
}

type ProviderSpecificSqlDbDetail struct {
	// Common Fields
	Provider           string `json:"provider"` // aws, azure, gcp, ncp
	Region             string `json:"region,omitempty"`
	Zone               string `json:"zone,omitempty"`
	ResourceIdentifier string `json:"resource_identifier"`

	// AWS Specific
	Status            string   `json:"status,omitempty"`
	DNSZoneID         string   `json:"dns_zone_id,omitempty"`
	SecurityGroupIDs  []string `json:"security_group_ids,omitempty"`
	SubnetGroupName   string   `json:"subnet_group_name,omitempty"`
	StorageEncrypted  bool     `json:"storage_encrypted,omitempty"`
	StorageThroughput int      `json:"storage_throughput,omitempty"`
	StorageIOPS       int      `json:"storage_iops,omitempty"`
	Replicas          []string `json:"replicas,omitempty"`
	IsMultiAZ         bool     `json:"is_multi_az,omitempty"`

	// Azure Specific
	ResourceGroupName         string `json:"resource_group_name,omitempty"`
	DatabaseName              string `json:"database_name,omitempty"`
	Charset                   string `json:"charset,omitempty"`
	Collation                 string `json:"collation,omitempty"`
	StorageAutogrowEnabled    bool   `json:"storage_autogrow_enabled,omitempty"`
	IOScalingEnabled          bool   `json:"io_scaling_enabled,omitempty"`
	BackupRetentionDays       int    `json:"backup_retention_days,omitempty"`
	GeoRedundantBackupEnabled bool   `json:"geo_redundant_backup_enabled,omitempty"`
	ReplicaCapacity           int    `json:"replica_capacity,omitempty"`
	ReplicationRole           string `json:"replication_role,omitempty"`

	// GCP Specific
	Project          string `json:"project,omitempty"`
	AvailabilityType string `json:"availability_type,omitempty"`

	// NCP Specific
	HostIP                    string           `json:"host_ip,omitempty"`
	ServerNamePrefix          string           `json:"server_name_prefix,omitempty"`
	ServerInstances           []ServerInstance `json:"server_instances,omitempty"`
	VpcNo                     string           `json:"vpc_no,omitempty"`
	SubnetNo                  string           `json:"subnet_no,omitempty"`
	AccessControlGroupNoList  []string         `json:"access_control_group_no_list,omitempty"`
	BackupEnabled             bool             `json:"backup_enabled,omitempty"`
	BackupTime                string           `json:"backup_time,omitempty"`
	BackupFileRetentionPeriod int              `json:"backup_file_retention_period,omitempty"`
	IsMultiZone               bool             `json:"is_multi_zone,omitempty"`
	IsStorageEncryption       bool             `json:"is_storage_encryption,omitempty"`
}

type ServerInstance struct {
	Name             string `json:"name"`
	Role             string `json:"role"`
	CPUCount         int    `json:"cpu_count"`
	MemorySize       int64  `json:"memory_size"`
	CreateDate       string `json:"create_date"`
	Uptime           string `json:"uptime"`
	ServerInstanceNo string `json:"server_instance_no"`
}

// type OutputAWSSqlDbInfo struct {
// 	Terrarium struct {
// 		ID string `json:"id"`
// 	} `json:"terrarium"`
// 	AWS struct {
// 		InstanceIdentifier string   `json:"instance_identifier"`
// 		ConnectionInfo     string   `json:"connection_info"`
// 		Port               int      `json:"port"`
// 		AdminUsername      string   `json:"admin_username"`
// 		DatabaseEngine     string   `json:"database_engine"`
// 		EngineVersion      string   `json:"engine_version"`
// 		Region             string   `json:"region"`
// 		VpcID              string   `json:"vpc_id"`
// 		SubnetIDs          []string `json:"subnet_ids"`
// 		SecurityGroupName  string   `json:"security_group_name"`
// 	} `json:"aws"`
// }

// type OutputAzureSqlDbInfo struct {
// 	Terrarium struct {
// 		ID string `json:"id"`
// 	} `json:"terrarium"`
// 	Azure struct {
// 		InstanceIdentifier string `json:"instance_identifier"`
// 		ConnectionInfo     string `json:"connection_info"`
// 		Port               int    `json:"port"`
// 		AdminUsername      string `json:"admin_username"`
// 		DatabaseName       string `json:"database_name"`
// 		Region             string `json:"region"`
// 		ResourceGroup      string `json:"resource_group"`
// 	} `json:"azure"`
// }

// type OutputGCPSqlDbInfo struct {
// 	Terrarium struct {
// 		ID string `json:"id"`
// 	} `json:"terrarium"`
// 	GCP struct {
// 		InstanceIdentifier string `json:"instance_identifier"`
// 		DatabaseName       string `json:"database_name"`
// 		AdminUsername      string `json:"admin_username"`
// 		ConnectionInfo     string `json:"connection_info"`
// 		IPAddress          string `json:"ip_address"`
// 		Port               int    `json:"port"`
// 		Region             string `json:"region"`
// 	} `json:"gcp"`
// }

// type OutputNCPSqlDbInfo struct {
// 	Terrarium struct {
// 		ID string `json:"id"`
// 	} `json:"terrarium"`
// 	NCP struct {
// 		InstanceIdentifier string `json:"instance_identifier"`
// 		ConnectionInfo     string `json:"connection_info"`
// 		AdminUsername      string `json:"admin_username"`
// 		DatabaseName       string `json:"database_name"`
// 		Port               int    `json:"port"`
// 		Region             string `json:"region"`
// 	} `json:"ncp"`
// }
