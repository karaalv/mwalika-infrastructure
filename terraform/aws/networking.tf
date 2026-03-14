# This file contains networking resources used
# throughout the infrastructure, such as VPCs and subnets.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
	filter {
		name   = "vpc-id"
		values = [data.aws_vpc.default.id]
	}
}