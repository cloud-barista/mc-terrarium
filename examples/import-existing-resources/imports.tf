import {
  to = aws_vpc.my-imported-vpc
  id = "xxxxxx"
}

resource "aws_vpc" "my-imported-vpc" {
  # name = "my-importe-vpc-name"
  # (other resource arguments...)
}

# References
# https://developer.hashicorp.com/terraform/language/v1.5.x/import
