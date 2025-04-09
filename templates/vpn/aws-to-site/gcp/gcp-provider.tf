# Configure GCP Provider
provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = try(var.vpn_config.target_csp.gcp.region, "asia-northeast3") # Default: "asia-northeast3", Seoul region, Korea
}
