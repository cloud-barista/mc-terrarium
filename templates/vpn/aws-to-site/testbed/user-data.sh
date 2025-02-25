#!/bin/bash
set -euo pipefail

# Redirect output to log file for debugging
exec > >(tee /var/log/user-data-debug.log) 2>&1

# Ensure ubuntu user exists with correct permissions
if ! id "ubuntu" &>/dev/null; then
    # Create user with sudo privileges
    useradd -m -s /bin/bash -G sudo ubuntu
else
    # Ensure user is in sudo group if already exists
    usermod -aG sudo ubuntu
fi

# Set up sudo access for ubuntu user without password
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu

# Set up SSH directory
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Add SSH public key
echo "${ssh_public_key}" > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Harden SSH configuration
sed -i -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
       -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
       -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' \
       /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

# Verify user creation and sudo access
id ubuntu
sudo -l -U ubuntu