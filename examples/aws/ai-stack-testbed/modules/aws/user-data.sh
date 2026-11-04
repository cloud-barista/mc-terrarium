#!/bin/bash
set -euo pipefail

# Redirect output to log file for debugging
exec > >(tee /var/log/user-data-debug.log) 2>&1

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

# Disable unattended-upgrades and apt-daily timers immediately so background package upgrades
# do not hold dpkg locks or restart containerd/docker during post-deployment setup scripts
systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null || true
systemctl disable apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null || true
systemctl mask apt-daily.service apt-daily-upgrade.service unattended-upgrades.service 2>/dev/null || true
if [ -d /etc/needrestart/conf.d ]; then
    echo '$nrconf{restart} = "l";' > /etc/needrestart/conf.d/99-autorestart.conf || true
fi

# ============================================================
# 1. Hostname Configuration (Required for Beetle Cluster Grouping)
# ============================================================
hostnamectl set-hostname "${vm_name}"
if ! grep -q "127.0.1.1 ${vm_name}" /etc/hosts; then
    echo "127.0.1.1 ${vm_name}" >> /etc/hosts
fi

# ============================================================
# 2. User & SSH Access Configuration
# ============================================================
if ! id "ubuntu" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo ubuntu
else
    usermod -aG sudo ubuntu
fi

echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu

mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

echo "${ssh_public_key}" > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

%{ if ssh_private_key != "" ~}
# Install shared SSH private key on Cloud-Migrator node for passwordless access to source nodes
cat << 'SSH_KEY_EOF' > /home/ubuntu/.ssh/id_rsa
${ssh_private_key}
SSH_KEY_EOF
chmod 600 /home/ubuntu/.ssh/id_rsa
cat << 'SSH_CFG_EOF' > /home/ubuntu/.ssh/config
Host 10.0.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
SSH_CFG_EOF
chmod 600 /home/ubuntu/.ssh/config

mkdir -p /home/ubuntu/.cloud-barista
chmod 700 /home/ubuntu/.cloud-barista
chown -R ubuntu:ubuntu /home/ubuntu/.cloud-barista
%{ endif ~}

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Enable pubkey auth and SSH Agent Forwarding (required for CM-Beetle transx direct rsync mode)
sed -i -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
       -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
       -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' \
       -e 's/#AllowAgentForwarding yes/AllowAgentForwarding yes/g' \
       /etc/ssh/sshd_config

systemctl restart ssh

# Ensure rsync, curl, jq are installed on all VMs
apt-get -o DPkg::Lock::Timeout=600 update -qq
apt-get -o DPkg::Lock::Timeout=600 install -y -qq rsync curl jq

# ============================================================
# 3. Host Firewall (UFW) Configuration per Service Role
# ============================================================
if [ "${service_role}" != "general" ] && [ "${service_role}" != "cloud-migrator" ]; then
    apt-get -o DPkg::Lock::Timeout=600 install -y -qq ufw

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
fi

case "${service_role}" in
  "ai-webui")
    ufw allow 3000/tcp comment 'Open WebUI HTTP'
    ufw allow 11434/tcp comment 'Ollama LLM API'
    ;;
  "ai-worker")
    ufw allow 11434/tcp comment 'Ollama Worker API'
    ufw allow 8000/tcp comment 'vLLM Vector Worker API'
    ;;
  "spark-master")
    ufw allow 8080/tcp comment 'Spark Master / Airflow Web UI'
    ufw allow 7077/tcp comment 'Spark Cluster Master RPC'
    ;;
  "spark-worker")
    ufw allow 8081/tcp comment 'Spark Worker Web UI'
    ufw allow 7077/tcp comment 'Spark Worker RPC'
    ;;
  "etl")
    ufw allow 9092/tcp comment 'Kafka Broker'
    ufw allow 5044/tcp comment 'Logstash Beats ETL'
    ;;
  "postgres")
    ufw allow 5432/tcp comment 'PostgreSQL Database'
    ufw deny 80/tcp comment 'Block HTTP'
    ufw deny 443/tcp comment 'Block HTTPS'
    ;;
  "backend-api")
    ufw allow 80/tcp comment 'Nginx HTTP'
    ufw allow 443/tcp comment 'Nginx HTTPS'
    ufw allow 8000/tcp comment 'FastAPI Application'
    ufw allow 8080/tcp comment 'Alternative HTTP'
    ;;
  "storage")
    ufw allow 9000/tcp comment 'MinIO S3 API'
    ufw allow 9001/tcp comment 'MinIO Console'
    ufw allow 2049/tcp comment 'NFS TCP'
    ufw allow 2049/udp comment 'NFS UDP'
    ufw allow 111/tcp comment 'RPC portmapper'
    ;;
  "redis")
    ufw allow 6379/tcp comment 'Redis Cache'
    ;;
  "nginx")
    ufw allow 80/tcp comment 'Nginx HTTP'
    ufw allow 443/tcp comment 'Nginx HTTPS'
    ufw allow 8080/tcp comment 'Alternative HTTP'
    ufw deny 3306/tcp comment 'Block MySQL'
    ufw deny 5432/tcp comment 'Block PostgreSQL'
    ;;
  "nfs")
    ufw allow 2049/tcp comment 'NFS'
    ufw allow 2049/udp comment 'NFS UDP'
    ufw allow 111/tcp comment 'RPC portmapper'
    ufw deny 80/tcp comment 'Block HTTP'
    ufw deny 443/tcp comment 'Block HTTPS'
    ;;
  "mariadb")
    ufw allow from 10.0.0.0/16 to any port 3306 comment 'MariaDB internal'
    ufw deny from any to any port 3306 comment 'Block external MySQL'
    ;;
  "tomcat")
    ufw allow 8080/tcp comment 'Tomcat HTTP'
    ufw allow 8443/tcp comment 'Tomcat HTTPS'
    ufw allow 80/tcp comment 'HTTP proxy'
    ufw allow 443/tcp comment 'HTTPS proxy'
    ;;
  "haproxy")
    ufw allow 80/tcp comment 'HAProxy HTTP'
    ufw allow 443/tcp comment 'HAProxy HTTPS'
    ufw allow from 10.0.0.0/16 to any port 8404 comment 'HAProxy stats'
    ;;
  "cloud-migrator"|"general"|*)
    echo "Cloud-Migrator / general purpose server (${vm_name}) - Security Group handles firewall rules"
    ;;
esac

if [ "${service_role}" != "general" ] && [ "${service_role}" != "cloud-migrator" ]; then
    ufw allow from 10.0.0.0/16 comment 'Internal VPC traffic'
    ufw deny 23/tcp comment 'Block Telnet'
    ufw deny 135/tcp comment 'Block RPC'
    ufw deny 139/tcp comment 'Block NetBIOS'
    ufw deny 445/tcp comment 'Block SMB'
    ufw logging on
    ufw --force enable

    echo "=== UFW Status for ${vm_name} (${service_role}) ===" > /var/log/ufw-status.log
    ufw status verbose >> /var/log/ufw-status.log
else
    echo "=== Security Group Only for ${vm_name} (${service_role}) ===" > /var/log/ufw-status.log
    echo "UFW not configured - using AWS Security Group rules only" >> /var/log/ufw-status.log
fi

echo "${service_role}" > /etc/vm-service-role

id ubuntu
sudo -l -U ubuntu
