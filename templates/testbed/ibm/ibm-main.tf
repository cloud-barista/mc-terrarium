# IBM module
module "ibm" {
  source = "./modules/ibm"

  terrarium_id = var.terrarium_id
  # region       = var.region
  public_key = tls_private_key.ssh.public_key_openssh
}
