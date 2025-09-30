# DCS Basic Infrastructure Example

This example demonstrates how to create basic networking and compute infrastructure in DCS (DevStack Cloud Service) using OpenTofu.

## Overview

This example creates a minimal but complete infrastructure including:

- **Network Infrastructure**: Private network, subnet, router with external connectivity
- **Security Groups**: Configured to allow SSH, HTTP, HTTPS, and ICMP traffic
- **Compute Instances**: Two Ubuntu 22.04 instances with m1.medium flavor
- **Floating IPs**: Public IP addresses for external access
- **Key Pair**: SSH key pair for instance access

## Architecture

```
DCS Infrastructure
├── Private Network
│   ├── Subnet (192.168.100.0/26)
│   ├── Router (connected to external network)
│   └── Security Group (SSH, HTTP, HTTPS, ICMP)
├── Primary Instance (m1.medium, ubuntu-22.04)
│   ├── Private IP: 192.168.100.x
│   ├── Floating IP: Public IP
│   └── Nginx Web Server
└── Secondary Instance (m1.medium, ubuntu-22.04)
    ├── Private IP: 192.168.100.y
    ├── Floating IP: Public IP
    └── Nginx Web Server
```

## Prerequisites

### DCS Environment

1. **DCS Installation**: Working DCS environment
2. **Images**: Ubuntu 22.04 image available in Glance
3. **Flavors**: m1.medium flavor available
4. **Networks**: External network 'public' configured with floating IP pool
5. **Access**: Network connectivity to DCS API endpoints

### Required Tools

- [OpenTofu](https://opentofu.org/) >= 1.8.3

### SSH Key

SSH keys are automatically generated using the TLS provider. No manual key setup required.

## Configuration

### 1. Set up OpenStack credentials

```bash
# Edit the credential file with your DCS (DevStack Cloud Service) settings
vi ../../secrets/credential-openstack.env

# Example content:
# OS_USERNAME=demo
# OS_PROJECT_NAME=demo
# OS_PASSWORD=your_password
# OS_AUTH_URL=http://your-dcs-ip:5000/v3
# OS_REGION_NAME=RegionOne

# Load the credentials
source ../../secrets/load-openstack-cred-env.sh
```

### 2. Configure project settings

```bash
# Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# Key settings to verify:
# - subnet_cidr = "192.168.100.0/26"
# - instance_flavor = "m1.medium"
# - instance_image = "ubuntu-22.04"
# Note: SSH key pair is automatically generated and managed
```

## Verification of Prerequisites

Before running OpenTofu, verify your DCS (DevStack Cloud Service) environment:

```bash
# Test OpenStack CLI connectivity (optional)
openstack token issue

# Check available flavors (should include m1.medium)
openstack flavor list

# Check available images (should include ubuntu-22.04)
openstack image list
```

## Deployment

```bash
# 1. Load OpenStack credentials
source ../../secrets/load-openstack-cred-env.sh

# 2. Verify credentials
echo $OS_AUTH_URL

# 3. Initialize and deploy
tofu init
tofu plan
tofu apply

# 4. View results
tofu output
```

## Testing and Verification

### Access Instances

```bash
# Get floating IPs from output
tofu output instance_info
tofu output secondary_instance_info

# Save the private key to a file
tofu output -raw ssh_private_key > dcs-key.pem
chmod 600 dcs-key.pem

# SSH to instances
ssh -i dcs-key.pem ubuntu@<floating_ip>

# Test web server
curl http://<floating_ip>
```

### Test Internal Connectivity

```bash
# From primary instance, ping secondary instance
ssh -i dcs-key.pem ubuntu@<primary_floating_ip>
ping <secondary_private_ip>
```

## Troubleshooting

### Common Issues

1. **Authentication Failed:**

   ```bash
   # Verify credentials
   openstack token issue
   ```

2. **Image/Flavor Not Found:**

   ```bash
   # Check available resources
   openstack image list | grep ubuntu-22.04
   openstack flavor list | grep m1.medium
   ```

3. **SSH Connection Issues:**

   ```bash
   # Ensure private key was saved correctly
   tofu output -raw ssh_private_key > dcs-key.pem

   # Set correct permissions (IMPORTANT!)
   chmod 600 dcs-key.pem

   # Test SSH connection with verbose output
   ssh -i dcs-key.pem -v ubuntu@<floating_ip>

   # If ping fails but SSH works, this is normal
   # Some OpenStack environments block ICMP but allow SSH
   ```

## Clean Up

```bash
# Destroy all resources
tofu destroy
```

## Next Steps

Once basic infrastructure is working:

1. Test connectivity between instances
2. Verify web server functionality
3. Use as foundation for VPN testing
4. Scale up with additional resources as needed

## References

- [DevStack company](https://www.devstack.co.kr/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [OpenStack Terraform Provider](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)
