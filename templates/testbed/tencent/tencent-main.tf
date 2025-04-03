# Tencent module
module "tencent" {
  source = "./modules/tencent"

  terrarium_id = var.terrarium_id
  # region       = var.region
  public_key = tls_private_key.ssh.public_key_openssh
}
