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
