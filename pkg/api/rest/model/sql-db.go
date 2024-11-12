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
	DBEngineVersion  string `json:"db_engine_version" example:"8.0.39"`
	DBInstanceSpec   string `json:"db_instance_spec" example:"db.t3.micro"`
	DBAdminUsername  string `json:"db_admin_username" example:"mydbadmin"`
	DBAdminPassword  string `json:"db_admin_password" example:"P@ssword1234!"`
	// DBInstanceID     string `json:"db_instance_identifier" example:"mydbinstance"`
}

type OutputAWSSqlDbInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	AWS struct {
		InstanceIdentifier string   `json:"instance_identifier"`
		ConnectionInfo     string   `json:"connection_info"`
		Port               int      `json:"port"`
		AdminUsername      string   `json:"admin_username"`
		DatabaseEngine     string   `json:"database_engine"`
		EngineVersion      string   `json:"engine_version"`
		Region             string   `json:"region"`
		VpcID              string   `json:"vpc_id"`
		SubnetIDs          []string `json:"subnet_ids"`
		SecurityGroupName  string   `json:"security_group_name"`
	} `json:"aws"`
}

type OutputAzureSqlDbInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	Azure struct {
		InstanceIdentifier string `json:"instance_identifier"`
		ConnectionInfo     string `json:"connection_info"`
		Port               int    `json:"port"`
		AdminUsername      string `json:"admin_username"`
		DatabaseName       string `json:"database_name"`
		Region             string `json:"region"`
		ResourceGroup      string `json:"resource_group"`
	} `json:"azure"`
}

type OutputGCPSqlDbInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	GCP struct {
		InstanceIdentifier string `json:"instance_identifier"`
		DatabaseName       string `json:"database_name"`
		AdminUsername      string `json:"admin_username"`
		ConnectionInfo     string `json:"connection_info"`
		IPAddress          string `json:"ip_address"`
		Port               int    `json:"port"`
		Region             string `json:"region"`
	} `json:"gcp"`
}

type OutputNCPSqlDbInfo struct {
	Terrarium struct {
		ID string `json:"id"`
	} `json:"terrarium"`
	NCP struct {
		InstanceIdentifier string `json:"instance_identifier"`
		ConnectionInfo     string `json:"connection_info"`
		AdminUsername      string `json:"admin_username"`
		DatabaseName       string `json:"database_name"`
		Port               int    `json:"port"`
		Region             string `json:"region"`
	} `json:"ncp"`
}
