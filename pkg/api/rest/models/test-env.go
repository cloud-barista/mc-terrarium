package models

type TfVarsTestEnv struct {
	AzureRegion            string `json:"azure-region" default:"koreacentral"`
	AzureResourceGroupName string `json:"azure-resource-group-name" default:"tofu-rg-01"`
	GcpRegion              string `json:"gcp-region" default:"asia-northeast3"`
	AwsRegion              string `json:"aws-region" default:"ap-northeast-2"`
}
