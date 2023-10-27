import {
  to = aws_vpc.test_vpc
  id = "xxxxxx"
}

resource "aws_vpc" "test_vpc" {
  # name = "my_vpc"
  # (other resource arguments...)
}

# References
# https://developer.hashicorp.com/terraform/language/v1.5.x/import
