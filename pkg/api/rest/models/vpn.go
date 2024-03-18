package models

type TfVarsGcpAwsVpnTunnel struct {
	MyImportedAWSVPCId      string `json:"my-imported-aws-vpc-id" default:""`
	MyImportedAWSSubnetId   string `json:"my-imported-aws-subnet-id" default:""`
	MyImportedGCPVPCName    string `json:"my-imported-gcp-vpc-name" default:""`
	MyImportedGCPSubnetName string `json:"my-imported-gcp-subnet-name" default:""`
}
