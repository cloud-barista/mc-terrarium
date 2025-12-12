# DCS module
module "dcs" {
  source = "./modules/dcs"

  terrarium_id = var.terrarium_id
  public_key   = tls_private_key.ssh.public_key_openssh
}
