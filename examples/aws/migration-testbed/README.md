# AWS Migration Testbed

This project provides a complete AWS migration testbed infrastructure with 6 VMs configured for different service roles. It's designed as a reusable Terraform module for testing migration scenarios.

## Requirements

- **OpenTofu/Terraform**: >= 1.0
- **AWS Provider**: ~> 5.42
- **TLS Provider**: ~> 4.0
- **AWS CLI**: Configured with appropriate credentials

## Overview

This testbed is designed for:

- Migration testing scenarios
- Multi-service application testing
- Network connectivity testing
- Service isolation testing
- Infrastructure as Code demonstrations

### VM Configuration

The testbed creates 6 VMs with different specifications and service roles:

| VM  | Instance Type | vCPU | Memory | Service Role | Firewall Configuration            |
| --- | ------------- | ---- | ------ | ------------ | --------------------------------- |
| vm1 | t3.small      | 2    | 4 GB   | nginx        | UFW: HTTP/HTTPS, 8080 (blocks DB) |
| vm2 | t3.xlarge     | 4    | 16 GB  | nfs          | UFW: NFS ports (blocks web)       |
| vm3 | t3.large      | 2    | 8 GB   | mariadb      | UFW: MySQL internal only          |
| vm4 | m5.xlarge     | 4    | 16 GB  | tomcat       | UFW: App server ports (blocks DB) |
| vm5 | m5.2xlarge    | 8    | 32 GB  | mariadb      | UFW: MariaDB container ports      |
| vm6 | m5.2xlarge    | 8    | 32 GB  | general      | Security Group only               |

### Service Roles and Firewall Configuration

Each VM configures firewall rules based on its service role. Service-specific VMs use UFW for detailed port management, while general purpose VMs rely on Security Group rules only:

#### nginx (Web Server)

- **Allowed**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (Alt HTTP)
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Web frontend, reverse proxy

#### nfs (File Server)

- **Allowed**: 22 (SSH), 2049 (NFS), 111 (RPC), 20048 (NFS mountd)
- **Blocked**: Web ports (80, 443, 8080)
- **Use Case**: Network file sharing

#### mariadb (Database Server)

- **Allowed**: 22 (SSH), 3306 (MySQL internal only), 4567-4568 (Galera)
- **Blocked**: External database access, web ports
- **Use Case**: Database backend

#### tomcat (Application Server)

- **Allowed**: 22 (SSH), 80, 443, 8080, 8443
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Java application server

#### haproxy (Load Balancer)

- **Allowed**: 22 (SSH), 80, 443, 8404 (stats)
- **Blocked**: Database ports (3306, 5432, 27017, 6379)
- **Use Case**: Load balancing, high availability

#### general (General Purpose)

- **Firewall**: Security Group rules only (no UFW configuration)
- **Access**: All ports managed through AWS Security Group
- **Use Case**: Flexible services where fine-grained port control isn't needed

### Project Structure

```
migration-testbed/
├── modules/
│   └── aws/                    # AWS Migration Testbed Module
│       ├── main.tf            # Module infrastructure
│       ├── variables.tf       # Module variables
|       ├── outputs.tf         # Module outputs
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

<details>
  <summary>Click to see the description of configuration files </summary>

### Configuration Files

#### Module-based Configuration

- `terraform-module.tfvars`: Example configuration for module usage
- `main-module.tf`: Root configuration using the module
- `variables-module.tf`: Root variables with validation
- `outputs-module.tf`: Root outputs forwarding module outputs

#### Direct Configuration (Legacy)

- `terraform.tfvars`: Direct configuration variables
- `main.tf`: Direct resource definitions
- `variables.tf`: Direct variable definitions
- `output.tf`: Direct output definitions

### Outputs

#### Infrastructure Information

- `testbed_info`: Basic infrastructure details
- `network_info`: VPC, subnet, gateway information
- `security_group_info`: Security group configuration

#### VM Information

- `vm_details`: Detailed VM specifications and IPs
- `vm_summary`: Summary with service roles
- `vm_public_ips`: Public IP addresses only
- `vm_private_ips`: Private IP addresses only
- `service_roles`: Service role assignments

#### SSH and Access

- `ssh_info`: Complete SSH information (sensitive)
- `quick_ssh_commands`: SSH commands for each VM (sensitive)
- `key_pair_info`: SSH key pair details

#### Deployment Summary

- `deployment_summary`: Overall deployment statistics

</details>

## Getting-started

### Deploy testbed

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

3. **Cleanup resource**:

   ```bash
   tofu destroy
   ```

### Extract SSH Access information

```bash
# Get private key
tofu output -json ssh_info | jq -r .private_key > private_key_mig_testbed.pem
chmod 600 private_key_mig_testbed.pem

# Get all SSH commands
tofu output -json ssh_info | jq -r '.vms[] | .command'

# Get specific VM info
# tofu output -json ssh_info | jq -r '.vms.vm1'
```

#### Test to connect to VMs (optional)

```bash
# Connect to specific VMs
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1)
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2)
# ... etc
```

### Firewall Verification

#### Check Firewall Status on All VMs

```bash
# Use the provided script to check all VMs at once
./check-firewall.sh

# Or check individual VMs manually (service-specific VMs only)
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) "sudo ufw status verbose"
```

> **Note**: VM6 (general purpose) uses Security Group rules only and will not have UFW configured.

#### Firewall Check Scripts

- **`check-firewall.sh`**: Comprehensive check with system info, UFW status, service roles, and error detection

#### Expected Firewall Rules by Service Role

- **nginx**: HTTP/HTTPS ports open, database ports blocked
- **nfs**: NFS ports (2049, 111, 20048) open, web ports blocked
- **mariadb**: MySQL port (3306) internal-only, web ports blocked
- **tomcat**: App server ports (8080, 8443) and web ports open, database ports blocked
- **haproxy**: Load balancer ports (80, 443, 8404) open, database ports blocked
- **general**: Security Group rules only (no UFW configuration)

#### Troubleshooting Firewall Issues

```bash
# If a VM fails firewall configuration during deployment
ssh -i private_key_mig_testbed.pem ubuntu@<VM_IP> "sudo journalctl -u cloud-final"

# Check user-data execution logs
ssh -i private_key_mig_testbed.pem ubuntu@<VM_IP> "sudo tail -f /var/log/user-data-debug.log"

# Manually reconfigure UFW if needed (service-specific VMs only)
ssh -i private_key_mig_testbed.pem ubuntu@<VM_IP> "
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  # Add service-specific rules...
  sudo ufw --force enable
"

# Note: General purpose VMs (vm6) use Security Group rules only
```

---

### Software Installation on the deployed infrastructure

#### Extract all remote command to install softwares

```bash
# Extract and display all remote installation commands
echo "=== Remote Installation Commands for Migration Testbed ==="
echo ""

echo "# VM1 (Nginx) - WordPress Installation:"
echo "ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) \\"
echo "  \"curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash\""
echo ""

echo "# VM2 (NFS) - NFS Server Installation:"
echo "ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2) \\"
echo "  \"curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-nfs.sh | sudo bash\""
echo ""

echo "# VM3 (MariaDB) - WordPress Installation:"
echo "ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm3) \\"
echo "  \"curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash\""
echo ""

echo "# VM4 (Tomcat) - Tomcat Container Installation:"
echo "ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm4) \\"
echo "  \"curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/container/tomcat/install-tomcat-container.sh | sudo bash\""
echo ""

echo "# VM5 (MariaDB) - MariaDB Container Installation:"
echo "ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm5) \\"
echo "  \"curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/container/mariadb/install-mariadb-container.sh | sudo bash\""
echo ""

```

### Software Status Verification

#### Extract all remote command to check the installed software version

> **Note**: The commands below include SSH options to suppress connection warnings and automatically accept host keys for smoother execution in testing environments.

```bash
# Extract and display all remote software version check commands
echo "=== Migration Testbed Software Status ==="

for vm in vm1 vm2 vm3 vm4 vm5 vm6; do
  echo "--- $vm ---"

  # Get VM IP and check connectivity
  VM_IP=$(tofu output -json vm_public_ips | jq -r .$vm 2>/dev/null)
  if [ "$VM_IP" = "null" ] || [ -z "$VM_IP" ]; then
    echo "Error: Cannot get IP for $vm"
    continue
  fi

  echo "VM IP: $VM_IP"

  # Get service role
  ROLE=$(ssh -i private_key_mig_testbed.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "cat /etc/vm-service-role 2>/dev/null || echo 'unknown'")
  echo "Role: $ROLE"

  case $ROLE in
    nginx)
      echo "Software versions check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'; \\"
      echo "   php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'; \\"
      echo "   mysql --version 2>/dev/null || echo 'MariaDB: Not installed'\""
      ;;
    nfs)
      echo "Software versions check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"dpkg -l nfs-kernel-server 2>/dev/null | grep '^ii' | awk '{print \\\$2 \\\" \\\" \\\$3}' || echo 'NFS: Not installed'; \\"
      echo "   cat /proc/fs/nfsd/versions 2>/dev/null | sed 's/^/NFS Protocol: /' || echo 'NFS Protocol: Not available'; \\"
      echo "   systemctl is-active nfs-kernel-server 2>/dev/null || echo 'NFS: Not running'\""
      ;;
    mariadb)
      echo "Software/Container versions check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"sudo docker --version 2>/dev/null || echo 'Docker: Not installed'; \\"
      echo "   if sudo docker --version >/dev/null 2>&1 && sudo docker ps | grep -q mariadb; then \\"
      echo "     echo 'MariaDB Container: Running'; \\"
      echo "     sudo docker ps --format 'table {{.Names}}\t{{.Status}}' | grep mariadb 2>/dev/null || echo 'MariaDB container: Not running'; \\"
      echo "     sudo docker exec mariadb_compose mariadb -uroot -prootpass -e 'SELECT VERSION();' 2>/dev/null || echo 'MariaDB: Not accessible'; \\"
      echo "   else \\"
      echo "     mysql --version 2>/dev/null || echo 'MariaDB: Not installed'; \\"
      echo "     nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'; \\"
      echo "     php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'; \\"
      echo "   fi\""
      ;;
    tomcat)
      echo "Container status check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"sudo docker --version 2>/dev/null || echo 'Docker: Not installed'; \\"
      echo "   sudo docker ps -a; \\"
      echo "   sudo docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'\""
      ;;
    haproxy)
      echo "Container status check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"sudo docker --version 2>/dev/null || echo 'Docker: Not installed'; \\"
      echo "   sudo docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'\""
      ;;
    general)
      echo "System info check command:"
      echo "ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP \\"
      echo "  \"systemctl is-active ufw 2>/dev/null || echo 'UFW: Not active'; \\"
      echo "   sudo docker --version 2>/dev/null || echo 'Docker: Not installed'\""
      ;;
    *)
      echo "Unknown role or not configured"
      ;;
  esac
  echo
done
```

---

## Commands on OpenTofu environment

### Software Installation on the deployed infrastructure

#### Install Nginx on vm1

```bash
# Execute WordPress installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash"
```

#### Install NFS Server on vm2

```bash
# Execute NFS installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-nfs.sh | sudo bash"
```

#### Install MariaDB on vm3

```bash
# Execute WordPress installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm3) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/package/install-wordpress.sh | sudo bash"
```

#### Install Tomcat container on vm4

```bash
# Execute Tomcat container installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm4) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/container/tomcat/install-tomcat-container.sh | sudo bash"
```

#### Install MariaDB container on vm5

```bash
# Execute MariaDB container installation script remotely
ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm5) \
  "curl -s https://raw.githubusercontent.com/cloud-barista/cm-grasshopper/refs/heads/main/examples/software-install-scripts/container/mariadb/install-mariadb-container.sh | sudo bash"
```

### Software Status Verification

#### Check Installed Software Status

```bash
# Check all VMs software status at once
for vm in vm1 vm2 vm3 vm4 vm5 vm6; do
  echo "=== $vm Software Status ==="
  ssh -i private_key_mig_testbed.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .$vm) \
    "echo 'Service Role:' && cat /etc/vm-service-role 2>/dev/null"
done
```

#### Quick Software Version Summary

> **Note**: This section uses SSH options to automatically handle host key verification and suppress connection warnings for seamless execution.

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
  ROLE=$(ssh -i private_key_mig_testbed.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "cat /etc/vm-service-role 2>/dev/null || echo 'unknown'")
  echo "Role: $ROLE"

  case $ROLE in
    nginx)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "
        nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'
        php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
        mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
      " 2>/dev/null
      ;;
    nfs)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "
        dpkg -l nfs-kernel-server 2>/dev/null | grep '^ii' | awk '{print \$2 \" \" \$3}' || echo 'NFS: Not installed'
        cat /proc/fs/nfsd/versions 2>/dev/null | sed 's/^/NFS Protocol: /' || echo 'NFS Protocol: Not available'
        systemctl is-active nfs-kernel-server 2>/dev/null || echo 'NFS: Not running'
      " 2>/dev/null
      ;;
    mariadb)
      echo "Software versions:"
      ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "
        sudo docker --version 2>/dev/null || echo 'Docker: Not installed'
        # Check if it's package-based MariaDB (VM3) or container-based (VM5)
        if sudo docker --version >/dev/null 2>&1 && sudo docker ps | grep -q mariadb; then
          echo 'MariaDB Container: Running'
          sudo docker --version 2>/dev/null || echo 'Docker: Not installed'
          sudo docker ps --format 'table {{.Names}}\t{{.Status}}' | grep mariadb 2>/dev/null || echo 'MariaDB container: Not running'
          sudo docker exec mariadb_compose mariadb -uroot -prootpass -e 'SELECT VERSION();' 2>/dev/null || echo 'MariaDB: Not accessible'
        else
          # Package-based MariaDB with WordPress
          mysql --version 2>/dev/null || echo 'MariaDB: Not installed'
          nginx -v 2>&1 | head -n 1 || echo 'Nginx: Not installed'
          php -v 2>/dev/null | head -n 1 || echo 'PHP: Not installed'
        fi
      " 2>/dev/null
      ;;
    tomcat)
      echo "Container status:"
      ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "
        sudo docker --version 2>/dev/null || echo 'Docker: Not installed'
        sudo docker ps -a
        sudo docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'
      " 2>/dev/null
      ;;
    haproxy)
      echo "Container status:"
      ssh -i private_key_mig_testbed.pem ubuntu@$VM_IP "
        sudo docker --version 2>/dev/null || echo 'Docker: Not installed'
        sudo docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -v NAMES || echo 'No containers running'
      " 2>/dev/null
      ;;
    general)
      echo "System info:"
      ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@$VM_IP "
        systemctl is-active ufw 2>/dev/null || echo 'UFW: Not active'
        sudo docker --version 2>/dev/null || echo 'Docker: Not installed'
      " 2>/dev/null
      ;;
    *)
      echo "Unknown role or not configured"
      ;;
  esac
  echo
done
```

#### Quick Access to Applications

```bash
# Get application URLs (after installation)
echo "WordPress on Nginx (vm1): http://$(tofu output -json vm_public_ips | jq -r .vm1)/"
echo "WordPress on MariaDB (vm3): http://$(tofu output -json vm_public_ips | jq -r .vm3)/"
echo "Tomcat Container (vm4): http://$(tofu output -json vm_public_ips | jq -r .vm4):8080/"

# Test application accessibility
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm1)/ || echo "WordPress not yet installed on vm1"
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm3)/ || echo "WordPress not yet installed on vm3"
curl -I http://$(tofu output -json vm_public_ips | jq -r .vm4):8080/ || echo "Tomcat container not yet installed on vm4"
```

---

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

---

## License

This project is provided as-is for testing and educational purposes.
