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

# Install and configure UFW (Uncomplicated Firewall)
apt-get update
apt-get install -y ufw

# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Always allow SSH (required for management)
ufw allow ssh

# Configure service-specific firewall rules based on VM role
case "${service_role}" in
  "nginx")
    echo "Configuring UFW for Nginx web server (${vm_name})"
    # Allow HTTP and HTTPS
    ufw allow 80/tcp comment 'Nginx HTTP'
    ufw allow 443/tcp comment 'Nginx HTTPS'
    # Allow common web admin ports
    ufw allow 8080/tcp comment 'Alternative HTTP'
    # Deny unnecessary database ports for security
    ufw deny 3306/tcp comment 'Block MySQL'
    ufw deny 5432/tcp comment 'Block PostgreSQL'
    # Allow monitoring
    ufw allow from 10.0.0.0/16 to any port 9113 comment 'Nginx Prometheus exporter'
    ;;
    
  "nfs")
    echo "Configuring UFW for NFS server (${vm_name})"
    # NFS requires multiple ports
    ufw allow 2049/tcp comment 'NFS'
    ufw allow 2049/udp comment 'NFS UDP'
    ufw allow 111/tcp comment 'RPC portmapper'
    ufw allow 111/udp comment 'RPC portmapper UDP'
    # NFS additional services
    ufw allow from 10.0.0.0/16 to any port 20048 comment 'NFS mountd'
    ufw allow from 10.0.0.0/16 to any port 32803 comment 'NFS statd'
    # Block web ports for security
    ufw deny 80/tcp comment 'Block HTTP'
    ufw deny 443/tcp comment 'Block HTTPS'
    # Allow only internal monitoring
    ufw allow from 10.0.0.0/16 to any port 9100 comment 'Node exporter'
    ;;
    
  "mariadb")
    echo "Configuring UFW for MariaDB database (${vm_name})"
    # Allow MariaDB/MySQL from internal network only
    ufw allow from 10.0.0.0/16 to any port 3306 comment 'MariaDB internal'
    # Allow Galera cluster communication (if clustering)
    ufw allow from 10.0.0.0/16 to any port 4567 comment 'Galera cluster'
    ufw allow from 10.0.0.0/16 to any port 4568 comment 'Galera IST'
    ufw allow from 10.0.0.0/16 to any port 4444 comment 'Galera SST'
    # Block all external web traffic
    ufw deny 80/tcp comment 'Block HTTP'
    ufw deny 443/tcp comment 'Block HTTPS'
    ufw deny 8080/tcp comment 'Block alt HTTP'
    # Explicitly deny external database access
    ufw deny from any to any port 3306 comment 'Block external MySQL'
    # Allow monitoring
    ufw allow from 10.0.0.0/16 to any port 9104 comment 'MySQL exporter'
    ;;
    
  "tomcat")
    echo "Configuring UFW for Tomcat application server (${vm_name})"
    # Allow Tomcat default ports
    ufw allow 8080/tcp comment 'Tomcat HTTP'
    ufw allow 8443/tcp comment 'Tomcat HTTPS'
    # Allow management ports from internal network only
    ufw allow from 10.0.0.0/16 to any port 8005 comment 'Tomcat shutdown'
    ufw allow from 10.0.0.0/16 to any port 8009 comment 'Tomcat AJP'
    # Allow standard web ports for reverse proxy
    ufw allow 80/tcp comment 'HTTP proxy'
    ufw allow 443/tcp comment 'HTTPS proxy'
    # Block database ports
    ufw deny 3306/tcp comment 'Block MySQL'
    ufw deny 5432/tcp comment 'Block PostgreSQL'
    # Allow JMX monitoring from internal network
    ufw allow from 10.0.0.0/16 to any port 9999 comment 'JMX monitoring'
    # Allow app-specific ports
    ufw allow from 10.0.0.0/16 to any port 8000:8100/tcp comment 'App range'
    ;;
    
  "haproxy")
    echo "Configuring UFW for HAProxy load balancer (${vm_name})"
    # Allow frontend ports
    ufw allow 80/tcp comment 'HAProxy HTTP'
    ufw allow 443/tcp comment 'HAProxy HTTPS'
    # Allow HAProxy stats page from internal network
    ufw allow from 10.0.0.0/16 to any port 8404 comment 'HAProxy stats'
    # Allow backend health check ports
    ufw allow from 10.0.0.0/16 to any port 8080:8090/tcp comment 'Backend health'
    # Allow custom load balancer ports
    ufw allow 8000/tcp comment 'Custom LB port'
    ufw allow 9000/tcp comment 'Admin interface'
    # Block database ports for security
    ufw deny 3306/tcp comment 'Block MySQL'
    ufw deny 5432/tcp comment 'Block PostgreSQL'
    # Allow monitoring
    ufw allow from 10.0.0.0/16 to any port 9101 comment 'HAProxy exporter'
    # Allow specific outbound for backend connections
    ufw allow out 8080/tcp comment 'Backend connections'
    ;;
    
  "general"|*)
    echo "Configuring UFW for general purpose server (${vm_name})"
    # Allow common web ports
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    # Allow common application ports
    ufw allow 8080/tcp comment 'Alt HTTP'
    ufw allow 3000/tcp comment 'Node.js apps'
    ufw allow 5000/tcp comment 'Flask/Python apps'
    # Allow database access from internal network only
    ufw allow from 10.0.0.0/16 to any port 3306 comment 'MySQL internal'
    ufw allow from 10.0.0.0/16 to any port 5432 comment 'PostgreSQL internal'
    # Allow monitoring
    ufw allow from 10.0.0.0/16 to any port 9100 comment 'Node exporter'
    ;;
esac

# Common security rules for all VMs
echo "Applying common security rules..."

# Allow internal network communication
ufw allow from 10.0.0.0/16 comment 'Internal VPC traffic'

# Block common attack ports
ufw deny 23/tcp comment 'Block Telnet'
ufw deny 135/tcp comment 'Block RPC'
ufw deny 139/tcp comment 'Block NetBIOS'
ufw deny 445/tcp comment 'Block SMB'

# Allow ping but limit rate
ufw allow in on any to any port 8 comment 'Allow ping'

# Log dropped packets for monitoring
ufw logging on

# Enable UFW
ufw --force enable

# Log UFW status and rules for verification
echo "=== UFW Status for ${vm_name} (${service_role}) ===" > /var/log/ufw-status.log
ufw status verbose >> /var/log/ufw-status.log
echo "=== UFW Rules ===" >> /var/log/ufw-status.log
ufw show added >> /var/log/ufw-status.log

# Create service role indicator file
echo "${service_role}" > /etc/vm-service-role

# Verify user creation and sudo access
id ubuntu
sudo -l -U ubuntu