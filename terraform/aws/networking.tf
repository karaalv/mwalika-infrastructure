# This file contains networking resources used
# throughout the infrastructure, such as VPCs and subnets.

data "aws_vpc" "default" {
  default = true
}