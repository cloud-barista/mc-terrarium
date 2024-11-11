package model

// TfVarsSqlDb represents the configuration structure based on the Terraform variables
type TfVarsSqlDb struct {
	TerrariumID      string `json:"terrarium_id" default:"" example:""`
	CSPRegion        string `json:"csp_region" example:"ap-northeast-2"`
	CSPVNetID        string `json:"csp_vnet_id" example:"vpc-12345678"`
	CSPSubnet1ID     string `json:"csp_subnet1_id" example:"subnet-1234abcd"`
	CSPSubnet2ID     string `json:"csp_subnet2_id" example:"subnet-abcd1234"`
	DBEnginePort     int    `json:"db_engine_port" example:"3306"`
	IngressCIDRBlock string `json:"ingress_cidr_block" example:"0.0.0.0/0"`
	EgressCIDRBlock  string `json:"egress_cidr_block" example:"0.0.0.0/0"`
	DBInstanceID     string `json:"db_instance_identifier" example:"mydbinstance"`
	DBEngineVersion  string `json:"db_engine_version" example:"8.0.39"`
	DBInstanceClass  string `json:"db_instance_class" example:"db.t3.micro"`
	DBAdminUsername  string `json:"db_admin_username" example:"mydbadmin"`
	DBAdminPassword  string `json:"db_admin_password" example:"mysdbpass"`
}
