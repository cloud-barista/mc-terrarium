# AWS Migration Testbed Module

This module creates a comprehensive AWS migration testbed with 6 VMs configured for different service roles.

## Features

- **VPC with Internet Gateway**: Complete networking setup
- **6 EC2 Instances**: Configurable VM specifications and service roles
- **Security Group**: Unified security configuration with UFW firewall per VM
- **SSH Key Management**: Auto-generated SSH keys for secure access
- **Service-Specific Configuration**: Each VM configured for specific services (nginx, nfs, mariadb, tomcat, haproxy, general)

## Usage

```hcl
module "migration_testbed" {
  source = "./modules/aws"

  terrarium_id = "my-testbed"
  aws_region   = "ap-northeast-2"

  vm_configurations = {
    vm1 = {
      instance_type = "t3.small"
      vcpu          = 2
      memory_gb     = 4
      service_role  = "nginx"
    }
    vm2 = {
      instance_type = "t3.xlarge"
      vcpu          = 4
      memory_gb     = 16
      service_role  = "nfs"
    }
    # ... more VMs
  }

  allowed_cidr_blocks = [
    "203.0.113.100/32"  # Your management IP
  ]
}
```

## Variables

| Name                  | Type           | Default                   | Description                                          |
| --------------------- | -------------- | ------------------------- | ---------------------------------------------------- |
| `terrarium_id`        | `string`       | -                         | **Required**. Unique ID for infrastructure resources |
| `aws_region`          | `string`       | `"ap-northeast-2"`        | AWS region for deployment                            |
| `vpc_cidr`            | `string`       | `"10.0.0.0/16"`           | CIDR block for VPC                                   |
| `subnet_cidr`         | `string`       | `"10.0.1.0/24"`           | CIDR block for subnet                                |
| `availability_zone`   | `string`       | `"ap-northeast-2a"`       | AZ for subnet placement                              |
| `ami_id`              | `string`       | `"ami-0f3a440bbcff3d043"` | Ubuntu 22.04 LTS AMI                                 |
| `allowed_cidr_blocks` | `list(string)` | `[]`                      | Additional CIDR blocks for access                    |
| `vm_configurations`   | `map(object)`  | -                         | **Required**. VM configurations with service roles   |
| `tags`                | `map(string)`  | `{}`                      | Additional tags for resources                        |

## VM Configuration Object

```hcl
vm_configurations = {
  vm_name = {
    instance_type = string  # AWS instance type (e.g., "t3.small")
    vcpu          = number  # vCPU count (informational)
    memory_gb     = number  # Memory in GB (informational)
    service_role  = string  # Service role: nginx, nfs, mariadb, tomcat, haproxy, general
  }
}
```

## Service Roles

Each VM is configured with UFW firewall rules specific to its service role:

- **nginx**: Web server (ports 80, 443, 8080)
- **nfs**: File server (ports 2049, 111, 20048)
- **mariadb**: Database server (port 3306 internal only)
- **tomcat**: Application server (ports 8080, 8443, 80, 443)
- **haproxy**: Load balancer (ports 80, 443, 8404)
- **general**: General purpose (ports 80, 443, 3000, 5000)

## Outputs

| Name                  | Description                                |
| --------------------- | ------------------------------------------ |
| `ssh_info`            | SSH connection information (sensitive)     |
| `testbed_info`        | Infrastructure information                 |
| `vm_details`          | Detailed VM information with service roles |
| `vm_summary`          | Summary of VM configurations               |
| `security_group_info` | Security group details                     |
| `network_info`        | Network infrastructure information         |
| `key_pair_info`       | SSH key pair information                   |
| `service_roles`       | Service roles assigned to VMs              |

## SSH Access

```bash
# Extract private key
terraform output -json ssh_info | jq -r .private_key > private_key.pem
chmod 600 private_key.pem

# Connect to VMs
terraform output -json ssh_info | jq -r '.vms.vm1.command'
# Outputs: ssh -i private_key.pem ubuntu@<public_ip>
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.42
- TLS Provider ~> 4.0

## Resources Created

- 1 VPC with DNS support
- 1 Public subnet
- 1 Internet Gateway
- 1 Route Table
- 1 Security Group (unified)
- 1 SSH Key Pair
- N EC2 Instances (based on vm_configurations)

## Security

- All VMs use the same Security Group with basic network access
- Individual VM-level security is handled by UFW firewall
- SSH access from VPC CIDR and specified additional CIDRs
- Private SSH keys are marked as sensitive outputs
