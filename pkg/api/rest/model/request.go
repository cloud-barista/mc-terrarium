package model

// Reqeust bodies for GCP-AWS VPN
type CreateInfracodeOfGcpAwsVpnRequest struct {
	TfVars TfVarsGcpAwsVpnTunnel `json:"tfVars"`
}

// Reqeust bodies for GCP-Azure VPN
type CreateInfracodeOfGcpAzureVpnRequest struct {
	TfVars TfVarsGcpAzureVpnTunnel `json:"tfVars"`
}

// Reqeust bodies for test-env
type CreateInfracodeOfTestEnvRequest struct {
	TfVars TfVarsTestEnv `json:"tfVars"`
}

// Request body for sql-db
type CreateInfracodeOfSqlDbRequest struct {
	TfVars TfVarsSqlDb `json:"tfVars"`
}
