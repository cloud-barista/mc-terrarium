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
3. Key pair created in DCS
4. VPNaaS plugin enabled in DCS
5. External network configured in DCS

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
   aws_key_pair_name = "your-aws-key-pair"

   # DCS Configuration
   openstack_user_name    = "your-username"
   openstack_tenant_name  = "your-project"
   openstack_password     = "your-password"
   openstack_auth_url     = "http://your-dcs-ip:5000/v3"
   openstack_key_pair_name = "your-openstack-key-pair"

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
aws ec2 describe-vpn-connections --region ap-northeast-2
```

**OpenStack VPN Status:**

```bash
openstack vpn ipsec site connection list
openstack vpn ipsec site connection show <connection-id>
```

### Test Connectivity

1. **SSH to AWS instance:**

   ```bash
   ssh -i ~/.ssh/your-key.pem ubuntu@<aws-instance-public-ip>
   ```

2. **SSH to OpenStack instance:**

   ```bash
   ssh -i ~/.ssh/your-key.pem ubuntu@<openstack-floating-ip>
   ```

3. **Test cross-cloud connectivity:**

   ```bash
   # From AWS instance, ping OpenStack instance
   ping <openstack-instance-private-ip>

   # From OpenStack instance, ping AWS instance
   ping <aws-instance-private-ip>
   ```

## Troubleshooting

### Common Issues

1. **VPN Tunnel Down:**

   - Check security groups allow VPN traffic
   - Verify shared secrets match
   - Check IKE/IPSec policy compatibility

2. **BGP Issues:**

   - Verify BGP ASN numbers are different
   - Check APIPA address configuration
   - Ensure proper routing table entries

3. **OpenStack VPNaaS Issues:**
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
