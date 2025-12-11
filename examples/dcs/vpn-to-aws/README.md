# AWS-DCS VPN Site-to-Site Connection

This example demonstrates how to create a Site-to-Site VPN connection between AWS and DCS (Data Center Simulator) using OpenTofu/Terraform.

## Architecture Overview

```
AWS VPC (10.0.0.0/16)                    DCS Network (192.168.0.0/24)
├── Subnet (10.0.1.0/24)                 ├── Subnet (192.168.0.0/26)
├── VPN Gateway                          ├── Router with external connectivity
├── Customer Gateways (2)                ├── VPNaaS Service
├── VPN Connection (2 tunnels)           ├── IKE Policy
└── EC2 Instance (test)                  ├── IPSec Policy
                                         ├── Site Connections (2)
                                         └── Compute Instance (test)
```

## Prerequisites

### AWS Requirements

1. AWS CLI configured with appropriate credentials
2. EC2 key pair created in the target region
3. Appropriate IAM permissions for VPC, EC2, and VPN resources

### DCS Requirements

1. DCS environment running and accessible
2. OpenStack CLI tools installed and configured
3. VPNaaS plugin enabled in DCS
4. External network configured in DCS

### Network Requirements

- **Non-overlapping CIDRs**: Ensure that the AWS VPC CIDR (default `10.0.0.0/16`) and DCS Network CIDR (default `192.168.0.0/24`) do not overlap with each other or your local network.

### Required Tools

- [OpenTofu](https://opentofu.org/) >= 1.8.3
- [AWS CLI](https://aws.amazon.com/cli/)
- [OpenStack CLI](https://docs.openstack.org/python-openstackclient/latest/)

## Configuration

1. **Copy the example variables file:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your specific values:**

   ```hcl
   # AWS Configuration
   aws_region     = "ap-northeast-2"
   aws_vpc_cidr   = "10.0.0.0/16"

   # DCS Configuration
   # Note: Credentials are best set via environment variables
   openstack_network_cidr = "192.168.0.0/24"
   openstack_subnet_cidr  = "192.168.0.0/26"

   # VPN Configuration
   vpn_shared_secret = "your-secure-shared-secret"
   ```

3. **Set up AWS credentials:**

   ```bash
   aws configure
   # OR
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```

4. **Set up OpenStack credentials (alternative to terraform.tfvars):**
   ```bash
   export OS_AUTH_URL="http://your-dcs-ip:5000/v3"
   export OS_USERNAME="your-username"
   export OS_PASSWORD="your-password"
   export OS_PROJECT_NAME="your-project"
   export OS_USER_DOMAIN_NAME="Default"
   export OS_PROJECT_DOMAIN_NAME="Default"
   ```

## Deployment

1. **Initialize OpenTofu:**

   ```bash
   tofu init
   ```

2. **Plan the deployment:**

   ```bash
   tofu plan
   ```

3. **Apply the configuration:**

   ```bash
   tofu apply
   ```

4. **View the outputs:**
   ```bash
   tofu output
   ```

## Verification

### Check VPN Status

**AWS VPN Connection:**

```bash
# Get VPN Connection ID
VPN_ID=$(tofu output -json aws_vpn_connection_id | jq -r .connection_1)

# Check Status
aws ec2 describe-vpn-connections --vpn-connection-ids $VPN_ID --region ap-northeast-2 --output table
```

**OpenStack VPN Status:**

```bash
# List Site Connections
openstack vpn ipsec site connection list

# Check Specific Connection Details
# Replace <connection-id> with ID from the list above
openstack vpn ipsec site connection show <connection-id>
```

### Test Connectivity

Follow these steps to verify the VPN connection and test cross-cloud connectivity.

#### 1. Prepare SSH Key

First, save the generated SSH private key and set the correct permissions.

```bash
# Save the private key to a file
tofu output -raw ssh_private_key_pem > key.pem

# Set read-only permissions for the owner (required for SSH)
chmod 600 key.pem
```

#### 2. Retrieve Instance Information

Get the Public and Private IP addresses for both AWS and OpenStack instances.

**AWS Instance:**

```bash
# Get Public IP
AWS_PUBLIC_IP=$(tofu output -json aws_instance_info | jq -r .public_ip)
echo "AWS Public IP: $AWS_PUBLIC_IP"

# Get Private IP
AWS_PRIVATE_IP=$(tofu output -json aws_instance_info | jq -r .private_ip)
echo "AWS Private IP: $AWS_PRIVATE_IP"
```

**OpenStack Instance:**

```bash
# Get Floating IP (Public)
OS_FLOATING_IP=$(tofu output -json openstack_instance_info | jq -r .floating_ip)
echo "OpenStack Floating IP: $OS_FLOATING_IP"

# Get Private IP
OS_PRIVATE_IP=$(tofu output -json openstack_instance_info | jq -r .private_ip)
echo "OpenStack Private IP: $OS_PRIVATE_IP"
```

#### 3. Access Instances via SSH

You can SSH into each instance using the saved key and the retrieved Public IPs.

**Connect to AWS Instance:**

```bash
ssh -i key.pem -o StrictHostKeyChecking=no ubuntu@$AWS_PUBLIC_IP
```

**Connect to OpenStack Instance:**

```bash
ssh -i key.pem -o StrictHostKeyChecking=no ubuntu@$OS_FLOATING_IP
```

#### 4. Perform Ping Test (Cross-Cloud)

Verify that the instances can communicate with each other using their **Private IPs** through the VPN tunnel.

**Option A: Automated One-Liner (Run from your local machine)**

Ping OpenStack Private IP **from** AWS Instance:

```bash
ssh -i key.pem -o StrictHostKeyChecking=no ubuntu@$AWS_PUBLIC_IP \
  ping -c 4 $OS_PRIVATE_IP
```

Ping AWS Private IP **from** OpenStack Instance:

```bash
ssh -i key.pem -o StrictHostKeyChecking=no ubuntu@$OS_FLOATING_IP \
  ping -c 4 $AWS_PRIVATE_IP
```

**Option B: Manual Test**

1.  SSH into the AWS Instance:
    ```bash
    ssh -i key.pem ubuntu@$AWS_PUBLIC_IP
    ```
2.  Ping the OpenStack Private IP:
    ```bash
    # Replace <OS_PRIVATE_IP> with the actual IP (e.g., 192.168.0.x)
    ping <OS_PRIVATE_IP>
    ```

## Troubleshooting

### Common Issues

1.  **VPN Tunnel Down (Phase 2 Negotiation Failed):**

    - **Traffic Selectors**: Ensure that the Local/Remote CIDRs match exactly on both sides.
      - AWS: `0.0.0.0/0` (Any) is recommended for maximum compatibility.
      - OpenStack: Uses the subnet CIDR (e.g., `192.168.0.0/26`) as the local selector.
    - **Shared Secret**: Verify that the Pre-Shared Key (PSK) matches in both AWS and OpenStack configurations.

2.  **Ping Fails but Tunnel is UP:**

    - **Security Groups**: Check if ICMP (Ping) is allowed in the Security Groups for both AWS and OpenStack instances.
    - **Routing**: Verify that the Route Tables in AWS and the Router in OpenStack have the correct routes to the peer network.
    - **DVR (Distributed Virtual Router)**: In some OpenStack environments (like DCS), DVR may cause routing issues with VPNaaS.
      - _Solution_: Ensure `distributed = false` is set in the `openstack_networking_router_v2` resource.

3.  **OpenStack VPNaaS Issues:**
    - Verify VPNaaS plugin is enabled: `openstack extension list | grep vpn`
    - Check router has external gateway: `openstack router show <router-id>`

- Verify external network connectivity

### Logs and Debugging

**AWS VPN Logs:**

- CloudWatch logs (if enabled)
- VPC Flow Logs

**OpenStack VPN Logs:**

- Neutron VPNaaS agent logs: `/var/log/neutron/neutron-vpn-agent.log`
- Check service status: `systemctl status neutron-vpn-agent`

## Security Considerations

1. **Shared Secret:** Use a strong, randomly generated shared secret
2. **Security Groups:** Configure security groups to allow only necessary traffic
3. **Key Management:** Secure your SSH keys and cloud credentials
4. **Network Segmentation:** Use appropriate subnet CIDRs to avoid conflicts

## Clean Up

To destroy all created resources:

```bash
tofu destroy
```

## Cost Considerations

### AWS Resources

- VPN Gateway: ~$36/month (always running)
- VPN Connection: ~$36/month per connection
- EC2 instance: Variable based on instance type
- Data transfer charges apply

### DCS

- DCS is typically free for development/testing
- Production OpenStack deployments may have hosting costs

## References

- [AWS VPN Documentation](https://docs.aws.amazon.com/vpn/)
- [OpenStack VPNaaS Documentation](https://docs.openstack.org/neutron-vpnaas/latest/)
- [DCS VPNaaS Plugin](https://docs.openstack.org/neutron-vpnaas/latest/install/devstack.html)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## Support

For issues with this example:

1. Check the troubleshooting section
2. Review AWS and OpenStack logs
3. Verify network connectivity and security groups
4. Ensure all prerequisites are met
