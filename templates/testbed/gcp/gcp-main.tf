# GCP module
module "gcp" {
  source = "./modules/gcp"

  terrarium_id = var.terrarium_id
  # region       = var.region
  public_key = tls_private_key.ssh.public_key_openssh
}
