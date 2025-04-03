output "ssh_info" {
  description = "SSH connection information"
  sensitive   = true
  value = {
    private_key = tls_private_key.ssh.private_key_pem
  }
}
