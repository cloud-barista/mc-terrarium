
## How to create AWS VPC with terraform

Related articles: 
- [2023-10-06-how-to-install-terraform](2023-10-06-how-to-install-terraform.md)

### Environment
- OS: Ubuntu 20.04.6 LTS (on WSL2)
- AWS CLI: 2.13.24 
- Python: 3.11.5
### Install AWS CLI

Ref. - [최신 버전의 AWS CLI 설치 또는 업데이트](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html#cliv2-linux-install)
```bash
# Download the installation file 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the installer
unzip awscliv2.zip

# Run the install program (add --update option for updates)
sudo ./aws/install

# Confirm the installation
aws --version
```

### Create IAM user

Please, see [How to create and configure AWS credentials for Amazon Keyspaces](https://docs.aws.amazon.com/keyspaces/latest/devguide/access.credentials.html)

Note - I already have my credential. I skip this step.

### Set credential

Prepare `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name`, and `Default output format`.

```bash
aws configure
```

Prompt Example
```bash
As an example
AWS Access Key ID [****************OLW4]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [****************Si6g]: YOUR_SECRET_ACCESS_KEY
Default region name [ap-northeast-2]: 
Default output format [json]:
```

### Setup Terraform
#### Install Terraform

[How-to-install-terraform](../2023-10-06-how-to-install-terraform.md)

#### Initialize Terraform

```bash
# Create a directory for Terraform files
cd ~
mkdir -p terraform
cd terraform

# Initialize Terraform
terraform init
```

#### Create a Terraform file
* Filename: main.tf
* Contents as follows:
```hcl
provider "aws" {
  region  = "ap-northeast-2"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "192.168.64.0/22"

  tags = {
    Name = "terraform-101"
  }
}
```

#### Check or predict resources to be created

```bash
terraform plan
```

Result:
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "example_vpc" {
      + arn                                  = (known after apply)
      + cidr_block                           = "192.168.64.0/22"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "terraform-101"
        }
      + tags_all                             = {
          + "Name" = "terraform-101"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```


#### Create the resources
```bash
terraform apply
```

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "example_vpc" {
      + arn                                  = (known after apply)
      + cidr_block                           = "192.168.64.0/22"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "terraform-101"
        }
      + tags_all                             = {
          + "Name" = "terraform-101"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

```bash
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-093814f9095e7da1b]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

On AWS console, it's possible to find the VPC by id above(`vpc-093814f9095e7da1b`)

#### Delete the resources

```bash
terraform destroy
```

```
aws_vpc.main: Refreshing state... [id=vpc-093814f9095e7da1b]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_vpc.main will be destroyed
  - resource "aws_vpc" "example_vpc" {
      - arn                                  = "arn:aws:ec2:ap-northeast-2:635484366616:vpc/vpc-093814f9095e7da1b" -> null
      - assign_generated_ipv6_cidr_block     = false -> null
      - cidr_block                           = "192.168.64.0/22" -> null
      - default_network_acl_id               = "acl-0ffb1e0618e423a26" -> null
      - default_route_table_id               = "rtb-08295d2242ec0d6d8" -> null
      - default_security_group_id            = "sg-01bde3789e70ae80f" -> null
      - dhcp_options_id                      = "dopt-fa6b9492" -> null
      - enable_dns_hostnames                 = false -> null
      - enable_dns_support                   = true -> null
      - enable_network_address_usage_metrics = false -> null
      - id                                   = "vpc-093814f9095e7da1b" -> null
      - instance_tenancy                     = "default" -> null
      - ipv6_netmask_length                  = 0 -> null
      - main_route_table_id                  = "rtb-08295d2242ec0d6d8" -> null
      - owner_id                             = "635484366616" -> null
      - tags                                 = {
          - "Name" = "terraform-101"
        } -> null
      - tags_all                             = {
          - "Name" = "terraform-101"
        } -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

```bash
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

```
aws_vpc.main: Destroying... [id=vpc-093814f9095e7da1b]
aws_vpc.main: Destruction complete after 0s

Destroy complete! Resources: 1 destroyed.
```

On AWS console, the VPC has the stauts of terminating or terminated.
