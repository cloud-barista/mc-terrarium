package models

type TfVarsVPNTunnels struct {
	MyImportedAWSVPCId      string `json:"my-imported-aws-vpc-id"`
	MyImportedAWSSubnetId   string `json:"my-imported-aws-subnet-id"`
	MyImportedGCPVPCName    string `json:"my-imported-gcp-vpc-name"`
	MyImportedGCPSubnetName string `json:"my-imported-gcp-subnet-name"`
}
