## TF configuration templates

The templates provided in this directory enable network infrastructure setup across Cloud Service Providers (CSPs). 

A set of templates defines providers, resources and relationships needed to configure a network infrastructure. 
Information to be inserted by users is set as variables in `variables.tf`.
You can set the value of a variable in `terraform.tfvars` or `terraform.tfvars.json`. 
You can create a file or modify an existing file as needed.

Currently, the following templates are available:
- GCP to AWS VPN tunnel,
- GCP to Azure VPN tunnel, and
- VM infrastructure over GCP, AWS, and Azure (as a test environment).
