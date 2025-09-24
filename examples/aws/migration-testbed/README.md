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

| VM  | Instance Type | vCPU | Memory | Service Role | UFW Firewall Rules |
|-----|---------------|------|--------|-------------|-------------------|
| vm1 | t3.small      | 2    | 4 GB   | nginx       | HTTP/HTTPS, 8080 (blocks DB) |
| vm2 | t3.xlarge     | 4    | 16 GB  | nfs         | NFS ports (blocks web) |
| vm3 | t3.large      | 2    | 8 GB   | mariadb     | MySQL internal only |
| vm4 | m5.xlarge     | 4    | 16 GB  | tomcat      | App server ports (blocks DB) |
| vm5 | m5.2xlarge    | 8    | 32 GB  | haproxy     | Load balancer ports (blocks DB) |
| vm6 | m5.2xlarge    | 8    | 32 GB  | general     | General ports, internal DB access |

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
tofu output -json ssh_info | jq -r .private_key > private_key.pem
chmod 600 private_key.pem

# Get all SSH commands
tofu output -json ssh_info | jq -r '.vms[] | .command'

# Get specific VM info
tofu output -json ssh_info | jq -r '.vms.vm1'
```

### Connect to VMs

```bash
# Connect to specific VMs
ssh -i private_key.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm1)
ssh -i private_key.pem ubuntu@$(tofu output -json vm_public_ips | jq -r .vm2)
# ... etc
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