# How to install Terraform

### Installation environment
- OS: Ubuntu 20.04.6 LTS (on WSL2)
- Terraform: v1.5.5 (I'm going to install Terrfarom v1.5.5 due to license issue.)
	- See [HashiCorp adopts Business Source License](https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license)
	- See [7. What products will be covered by BSL 1.1 in their next release?](https://www.hashicorp.com/license-faq#products-covered-by-bsl)

### Install Terraform
```bash
# Ensure that your system is up to date
sudo apt-get update
# Ensure that you have installed the dependencies, such as `gnupg`, `software-properties-common`, `curl`, and unzip packages.
sudo apt-get install -y software-properties-common gnupg2 curl unzip

### Install Terraform on Linux from tarball
# Set Terraform version
TERRAFORM_VERSION="1.5.5"

# Get tarball
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Unzip the tarball
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Move the terraform binary to `/usr/local/bin`
sudo mv terraform /usr/local/bin/

# Make the toll acccessible to all user accounts
which terraform

# Check the version of Terraform installed
terraform --version
```

#### Verify the installation
```bash
terraform -help
```
#### Enable tab completion
If you use either Bash or Zsh, you can enable tab completion for Terraform commands. 
To enable autocomplete, first ensure that a config file exists for your chosen shell.

```bash
touch ~/.bashrc
```

Then install the autocomplete package.
```bash
terraform -install-autocomplete
```


### Appendix

Ref: [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)(official guide to install the latest version of Terraform)
```bash
# Ensure that your system is up to date and you have installed the `gnupg`, `software-properties-common`, and `curl` packages installed. You will use these packages to verify HashiCorp's GPG signature and install HashiCorp's Debian package repository.
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Install the HashiCorp [GPG key](https://apt.releases.hashicorp.com/gpg "HashiCorp GPG key").
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify the key's fingerprint.
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# Add the official HashiCorp repository to your system. The `lsb_release -cs` command finds the distribution release codename for your current system, such as `buster`, `groovy`, or `sid`.
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Download the package information from HashiCorp.
sudo apt update

# Install Terraform from the new repository.
sudo apt-get install terraform
```

#### Verify the installation
```bash
terraform -help
```

#### Enable tab completion
If you use either Bash or Zsh, you can enable tab completion for Terraform commands. 

To enable autocomplete, first ensure that a config file exists for your chosen shell.
```bash
touch ~/.bashrc
```

Then install the autocomplete package.
```bash
terraform -install-autocomplete
```
