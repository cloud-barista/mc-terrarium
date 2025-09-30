# AWS Migration Testbed

This project provides a complete AWS migration testbed infrastructure with 6 VMs configured for different service roles. It's designed as a reusable Terraform module for testing migration scenarios.

## Project Structure

```
migration-testbed/
├── modules/
│   └── aws/                    # AWS Migration Testbed Module
│       ├── main.tf            # Module infrastructure
│       ├── variables.tf       # Module variables
│       ├── outputs.tf         # Module outputs
│       ├── terraform.tf       # Module requirements
│       ├── user-data.sh      # VM initialization script
│       └── README.md         # Module documentation
├── main-module.tf             # Root configuration using module
├── variables-module.tf        # Root variables
├── outputs-module.tf          # Root outputs
├── terraform-module.tfvars    # Example configuration
├── provider.tf               # Provider configuration
└── README.md                 # This file
```

## Quick Start

### Option 1: Use the Module (Recommended)

1. **Configure variables**:

   ```bash
   cp terraform-module.tfvars terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

2. **Deploy using module**:

   ```bash
   # Use module-based configuration
   cp main-module.tf main.tf
   cp variables-module.tf variables.tf
   cp outputs-module.tf outputs.tf

   # Initialize and deploy
   tofu init
   tofu plan
   tofu apply
   ```

### Option 2: Use Direct Configuration (Legacy)

1. **Use existing files**:

   ```bash
   # Files are already present:
   # - main.tf (direct resources)
   # - variables.tf (direct variables)
   # - output.tf (direct outputs)

   # Initialize and deploy
   tofu init
   tofu plan
   tofu apply
   ```

## VM Configuration

The testbed creates 6 VMs with different specifications and service roles:

| VM  | Instance Type | vCPU | Memory | Service Role | UFW Firewall Rules                |
| --- | ------------- | ---- | ------ | ------------ | --------------------------------- |
| vm1 | t3.small      | 2    | 4 GB   | nginx        | HTTP/HTTPS, 8080 (blocks DB)      |
| vm2 | t3.xlarge     | 4    | 16 GB  | nfs          | NFS ports (blocks web)            |
| vm3 | t3.large      | 2    | 8 GB   | mariadb      | MySQL internal only               |
| vm4 | m5.xlarge     | 4    | 16 GB  | tomcat       | App server ports (blocks DB)      |
| vm5 | m5.2xlarge    | 8    | 32 GB  | haproxy      | MariaDB container ports           |
| vm6 | m5.2xlarge    | 8    | 32 GB  | general      | General ports, internal DB access |

## Service Roles and Firewall Configuration

Each VM automatically configures UFW firewall rules based on its service role:

### nginx (Web Server)

- **Allowed**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (Alt HTTP)
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Web frontend, reverse proxy

### nfs (File Server)

- **Allowed**: 22 (SSH), 2049 (NFS), 111 (RPC), 20048 (NFS mountd)
- **Blocked**: Web ports (80, 443, 8080)
- **Use Case**: Network file sharing

### mariadb (Database Server)

- **Allowed**: 22 (SSH), 3306 (MySQL internal only), 4567-4568 (Galera)
- **Blocked**: External database access, web ports
- **Use Case**: Database backend

### tomcat (Application Server)

- **Allowed**: 22 (SSH), 80, 443, 8080, 8443
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Java application server

### haproxy (Load Balancer)

- **Allowed**: 22 (SSH), 80, 443, 8404 (stats)
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Load balancing, high availability

### general (General Purpose)

- **Allowed**: 22 (SSH), 80, 443, 3000, 5000, internal DB access
- **Use Case**: Flexible services, development

## Configuration Files

### Module-based Configuration

- `terraform-module.tfvars`: Example configuration for module usage
- `main-module.tf`: Root configuration using the module
- `variables-module.tf`: Root variables with validation
- `outputs-module.tf`: Root outputs forwarding module outputs

### Direct Configuration (Legacy)

- `terraform.tfvars`: Direct configuration variables
- `main.tf`: Direct resource definitions
- `variables.tf`: Direct variable definitions
- `output.tf`: Direct output definitions

## SSH Access

### Extract SSH Information

```bash
# Get private key
tofu output -json ssh_info | jq -r .private_key > private_key_mig_testbed.pem
chmod 600 private_key_mig_testbed.pem

# Get all SSH commands
tofu output -json ssh_info | jq -r '.vms[] | .command'

# Get specific VM info
tofu output -json ssh_info | jq -r '.vms.vm1'
```

### Connect to VMs

```bash
# Connect to specific VMs
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1)
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2)
# ... etc
```

## Software Installation on the deployed infrastructure

### Install Nginx on vm1

```bash
# Execute WordPress installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash"
```

### Install NFS Server on vm2

```bash
# Execute NFS installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-nfs.sh | sudo bash"
```

### Install MariaDB on vm3

```bash
# Execute WordPress installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm3) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash"
```

### Install Tomcat container on vm4

TBD

### Install MariaDB container on vm5

TBD

## Software Status Verification

### Check Installed Software Status

```bash
# Check all VMs software status at once
for vm in vm1 vm2 vm3 vm4 vm5 vm6; do
  echo "=== $vm Software Status ==="
  ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .$vm) \
    "echo 'Service Role:' && cat /etc/vm-service-role 2>/dev/null"
done
```

### Quick Software Version Summary

```bash
# Get software versions summary from all VMs
echo "=== Migration Testbed Software Status ==="

for vm in vm1 vm2 vm3 vm4 vm5 vm6; do
  echo "--- $vm ---"

  # Get VM IP and check connectivity
  VM_IP=$(tofu output -json vm_public_ips | jq -r .$vm 2>/dev/null)
  if [ "$VM_IP" = "null" ] || [ -z "$VM_IP" ]; then
    echo "Error: Cannot get IP for $vm"
    continue
  fi

  # Get service role
  ROLE=$(ssh -i private_key_mig_testbed.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$VM_IP "cat /etc/vm-service-role 2>/dev/null || echo 'unknown'")
  echo "Role: $ROLE"

  case $ROLE in
    nginx)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'
        php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
        mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
      " 2>/dev/null
      ;;
    nfs)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        dpkg -l nfs-kernel-server 2>/dev/null | grep '^ii' | awk '{print \$2 \" \" \$3}' || echo 'NFS: Not installed'
        cat /proc/fs/nfsd/versions 2>/dev/null | sed 's/^/NFS Protocol: /' || echo 'NFS Protocol: Not available'
        systemctl is-active nfs-kernel-server 2>/dev/null || echo 'NFS: Not running'
      " 2>/dev/null
      ;;
    mariadb)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
        nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'
        php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
      " 2>/dev/null
      ;;
    tomcat)
      echo "Container status:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        docker --version 2>/dev/null || echo 'Docker: Not installed'
        docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'
      " 2>/dev/null
      ;;
    haproxy)
      echo "Container status:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        docker --version 2>/dev/null || echo 'Docker: Not installed'
        docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'
      " 2>/dev/null
      ;;
    general)
      echo "System info:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        systemctl is-active ufw 2>/dev/null || echo 'UFW: Not active'
        docker --version 2>/dev/null || echo 'Docker: Not installed'
      " 2>/dev/null
      ;;
    *)
      echo "Unknown role or not configured"
      ;;
  esac
  echo
done
```

### Service-Specific Software Checks

#### Nginx Server (vm1) - WordPress

```bash
# Check service status and versions
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) "
echo '=== VM1 (Nginx) Software Status ==='
echo 'Service Status:'
systemctl is-active nginx php8.1-fpm mariadb 2>/dev/null || echo 'Some services not installed'
echo
echo 'Software Versions:'
nginx -v 2>&1 || echo 'Nginx: Not installed'
php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
echo
echo 'Process Check:'
pgrep -f nginx > /dev/null && echo 'Nginx: Running' || echo 'Nginx: Not running'
pgrep -f php-fpm > /dev/null && echo 'PHP-FPM: Running' || echo 'PHP-FPM: Not running'
pgrep -f mysql > /dev/null && echo 'MariaDB: Running' || echo 'MariaDB: Not running'
"
```

#### NFS Server (vm2)

```bash
# Check NFS service status and version
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2) "
echo '=== VM2 (NFS) Software Status ==='
echo 'Service Status:'
systemctl is-active nfs-kernel-server rpcbind 2>/dev/null || echo 'NFS services not installed'
echo
echo 'NFS Version:'
nfsstat -v 2>/dev/null || echo 'NFS: Not installed'
echo
echo 'Process Check:'
pgrep -f nfsd > /dev/null && echo 'NFS Server: Running' || echo 'NFS Server: Not running'
pgrep -f rpcbind > /dev/null && echo 'RPC Bind: Running' || echo 'RPC Bind: Not running'
echo
echo 'Exports Status:'
showmount -e localhost 2>/dev/null || echo 'No exports configured'
"
```

#### MariaDB Server (vm3) - WordPress

```bash
# Check MariaDB and web services status
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm3) "
echo '=== VM3 (MariaDB) Software Status ==='
echo 'Service Status:'
systemctl is-active mariadb nginx php8.1-fpm 2>/dev/null || echo 'Some services not installed'
echo
echo 'Software Versions:'
mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
nginx -v 2>&1 || echo 'Nginx: Not installed'
php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
echo
echo 'Process Check:'
pgrep -f mysql > /dev/null && echo 'MariaDB: Running' || echo 'MariaDB: Not running'
pgrep -f nginx > /dev/null && echo 'Nginx: Running' || echo 'Nginx: Not running'
pgrep -f php-fpm > /dev/null && echo 'PHP-FPM: Running' || echo 'PHP-FPM: Not running'
echo
echo 'Database Status:'
mysql -uroot -e 'SELECT VERSION();' 2>/dev/null || echo 'Database connection failed'
"
```

#### Tomcat Server (vm4) - Container

```bash
# Check Docker and Tomcat container status
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm4) "
echo '=== VM4 (Tomcat Container) Software Status ==='
echo 'Docker Status:'
systemctl is-active docker 2>/dev/null || echo 'Docker: Not installed'
docker --version 2>/dev/null || echo 'Docker: Not installed'
echo
echo 'Docker Process:'
pgrep -f dockerd > /dev/null && echo 'Docker Daemon: Running' || echo 'Docker Daemon: Not running'
echo
echo 'Container Status:'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'No containers or Docker not running'
echo
echo 'Tomcat Container Check:'
docker ps | grep tomcat > /dev/null && echo 'Tomcat Container: Running' || echo 'Tomcat Container: Not running'
"
```

#### MariaDB Container Server (vm5)

```bash
# Check Docker and MariaDB container status
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm5) "
echo '=== VM5 (MariaDB Container) Software Status ==='
echo 'Docker Status:'
systemctl is-active docker 2>/dev/null || echo 'Docker: Not installed'
docker --version 2>/dev/null || echo 'Docker: Not installed'
echo
echo 'Container Status:'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'No containers running'
echo
echo 'MariaDB Container Check:'
docker ps | grep mariadb > /dev/null && echo 'MariaDB Container: Running' || echo 'MariaDB Container: Not running'
"
```

### Quick Access to WordPress Sites

```bash
# Get WordPress URLs (after installation)
echo "WordPress on Nginx (vm1): http://$(tofu output -json vm_public_ips | jq -r .vm1)/"
echo "WordPress on MariaDB (vm3): http://$(tofu output -json vm_public_ips | jq -r .vm3)/"

# Test WordPress accessibility
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm1)/ || echo "WordPress not yet installed on vm1"
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm3)/ || echo "WordPress not yet installed on vm3"
```

### NFS Mount Test

```bash
# Test NFS mount from general server (vm6) after NFS installation
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm6) "
  sudo apt-get update &&
  sudo apt-get install -y nfs-common &&
  sudo mkdir -p /mnt/nfs-test &&
  sudo mount -t nfs $(tofu output -json vm_private_ips | jq -r .vm2):/nfs/share /mnt/nfs-test &&
  echo 'NFS mount successful - creating test file' &&
  echo 'Hello from vm6' | sudo tee /mnt/nfs-test/test-from-vm6.txt &&
  ls -la /mnt/nfs-test/ &&
  sudo umount /mnt/nfs-test
" || echo "NFS not yet installed or accessible"
```

### Quick Access to WordPress Sites

```bash
# Get WordPress URLs (after installation)
echo "WordPress on Nginx (vm1): http://$(tofu output -json vm_public_ips | jq -r .vm1)/"
echo "WordPress on MariaDB (vm3): http://$(tofu output -json vm_public_ips | jq -r .vm3)/"

# Test WordPress accessibility
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm1)/ || echo "WordPress not yet installed on vm1"
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm3)/ || echo "WordPress not yet installed on vm3"
```

### NFS Mount Test

```bash
# Test NFS mount from general server (vm6) after NFS installation
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm6) "
  sudo apt-get update &&
  sudo apt-get install -y nfs-common &&
  sudo mkdir -p /mnt/nfs-test &&
  sudo mount -t nfs $(tofu output -json vm_private_ips | jq -r .vm2):/nfs/share /mnt/nfs-test &&
  echo 'NFS mount successful - creating test file' &&
  echo 'Hello from vm6' | sudo tee /mnt/nfs-test/test-from-vm6.txt &&
  ls -la /mnt/nfs-test/ &&
  sudo umount /mnt/nfs-test
" || echo "NFS not yet installed or accessible"
```

#### HAProxy Server (vm5)

```bash
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm5) \
  "test -f /etc/haproxy/haproxy.cfg && echo 'HAProxy installed' || echo 'HAProxy not installed'"
```

#### General Server (vm6)

```bash
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm6) \
  "systemctl is-active ufw"
```

# Check general purpose server

ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm6) "
echo '=== Service Status ===' &&
systemctl is-active ufw &&
echo -e '\n=== Available Ports ===' &&
ss -tlnp | grep -E ':(80|443|3000|5000|8080)' &&
echo -e '\n=== System Resources ===' &&
free -h && df -h /
"

````

### Quick Health Check Script

```bash
# Create a comprehensive health check script
cat << 'EOF' > check-services.sh
#!/bin/bash
# Quick service health check for all VMs

for vm in vm1 vm2 vm3 vm4 vm5 vm6; do
  echo "=== $vm Health Check ==="
  VM_IP=$(tofu output -json vm_public_ips | jq -r .$vm)

  # Basic connectivity
  if ping -c 1 -W 3 $VM_IP &>/dev/null; then
    echo "✓ Network: Reachable"
  else
    echo "✗ Network: Unreachable"
    continue
  fi

  # SSH connectivity
  if ssh -i private_key_mig_testbed.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$VM_IP "exit" &>/dev/null; then
    echo "✓ SSH: Connected"

    # Service role and basic services
    ROLE=$(ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "cat /etc/vm-service-role 2>/dev/null || echo 'unknown'")
    echo "  Role: $ROLE"

    SSH_STATUS=$(ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "systemctl is-active ssh" 2>/dev/null)
    UFW_STATUS=$(ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "systemctl is-active ufw" 2>/dev/null)
    echo "  SSH: $SSH_STATUS, UFW: $UFW_STATUS"

    # Role-specific checks
    case $ROLE in
      nginx|mariadb)
        WP_STATUS=$(ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://localhost/" 2>/dev/null)
        echo "  WordPress HTTP: $WP_STATUS"
        ;;
      nfs)
        NFS_STATUS=$(ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "systemctl is-active nfs-kernel-server" 2>/dev/null)
        echo "  NFS: $NFS_STATUS"
        ;;
    esac
  else
    echo "✗ SSH: Connection failed"
  fi
  echo
done
EOF

chmod +x check-services.sh

# Run the health check
./check-services.sh
```

## Firewall Verification

### Check UFW Status on All VMs

```bash
# Use the provided script to check all VMs at once
./check-firewall.sh

# For a quick status check of all VMs
./simple-firewall-check.sh

# Or check individual VMs manually
ssh -i private_key.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) "sudo ufw status verbose"
```

### Firewall Check Scripts

- **`check-firewall.sh`**: Comprehensive check with system info, UFW status, service roles, and error detection
- **`simple-firewall-check.sh`**: Basic UFW status check for all VMs
- **`quick-firewall-check.sh`**: Ultra-quick connectivity and UFW status check

### Expected Firewall Rules by Service Role

- **nginx**: HTTP/HTTPS ports open, database ports blocked
- **nfs**: NFS ports (2049, 111, 20048) open, web ports blocked
- **mariadb**: MySQL port (3306) internal-only, web ports blocked
- **tomcat**: App server ports (8080, 8443) and web ports open, database ports blocked
- **haproxy**: Load balancer ports (80, 443, 8404) open, database ports blocked
- **general**: Web and app ports open, database ports internal-only

### Troubleshooting Firewall Issues

```bash
# If a VM fails firewall configuration during deployment
ssh -i private_key.pem ubuntu@<VM_IP> "sudo journalctl -u cloud-final"

# Check user-data execution logs
ssh -i private_key.pem ubuntu@<VM_IP> "sudo tail -f /var/log/user-data-debug.log"

# Manually reconfigure UFW if needed
ssh -i private_key.pem ubuntu@<VM_IP> "
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  # Add service-specific rules...
  sudo ufw --force enable
"
```

## Outputs

### Infrastructure Information

- `testbed_info`: Basic infrastructure details
- `network_info`: VPC, subnet, gateway information
- `security_group_info`: Security group configuration

### VM Information

- `vm_details`: Detailed VM specifications and IPs
- `vm_summary`: Summary with service roles
- `vm_public_ips`: Public IP addresses only
- `vm_private_ips`: Private IP addresses only
- `service_roles`: Service role assignments

### SSH and Access

- `ssh_info`: Complete SSH information (sensitive)
- `quick_ssh_commands`: SSH commands for each VM (sensitive)
- `key_pair_info`: SSH key pair details

### Deployment Summary

- `deployment_summary`: Overall deployment statistics

## Customization

### Add More VMs

```hcl
vm_configurations = {
  # Existing VMs...

  vm7 = {
    instance_type = "t3.medium"
    vcpu          = 2
    memory_gb     = 4
    service_role  = "nginx"
  }
}
```

### Modify Network Settings

```hcl
vpc_cidr    = "172.16.0.0/16"
subnet_cidr = "172.16.1.0/24"
availability_zone = "ap-northeast-2b"
```

### Add Management Access

```hcl
allowed_cidr_blocks = [
  "203.0.113.100/32",  # Your public IP
  "192.168.1.0/24",    # Office network
  "10.1.0.0/16"        # VPN network
]
```

## Module Usage in Other Projects

```hcl
module "migration_testbed" {
  source = "github.com/your-org/migration-testbed//modules/aws"

  terrarium_id = "my-test-env"
  aws_region   = "us-west-2"

  vm_configurations = {
    web = {
      instance_type = "t3.small"
      vcpu          = 2
      memory_gb     = 4
      service_role  = "nginx"
    }
    db = {
      instance_type = "t3.medium"
      vcpu          = 2
      memory_gb     = 4
      service_role  = "mariadb"
    }
  }

  allowed_cidr_blocks = [
    "203.0.113.0/24"
  ]
}
```

## Requirements

- **OpenTofu/Terraform**: >= 1.0
- **AWS Provider**: ~> 5.42
- **TLS Provider**: ~> 4.0
- **AWS CLI**: Configured with appropriate credentials

## Resource Cleanup

```bash
tofu destroy
```

## Support

This testbed is designed for:

- Migration testing scenarios
- Multi-service application testing
- Network connectivity testing
- Service isolation testing
- Infrastructure as Code demonstrations

## License

This project is provided as-is for testing and educational purposes.
````
