package model

type TestbedConfigDetail struct {
	TerrariumId      string   `json:"terrarium_id" default:"" example:""`
	DesiredProviders []string `json:"desired_providers" example:"aws,azure,gcp,alibaba,tencent,ibm,dcs"`
}
