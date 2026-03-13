# This file contains security group resources used
# throughout the infrastructure, such as for EC2 instances.

# - CloudFront Managed Prefix List -

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# - EC2 Security Groups -

resource "aws_security_group" "ec2_security_group" {
  name        = "mwalika-ec2-security-group"
  description = "Security group for EC2 instances in the Mwalika infrastructure"
  vpc_id      = data.aws_vpc.default.id

}

# Inbound rules (Only allow traffic to service pods)
resource "aws_vpc_security_group_ingress_rule" "cloudfront_to_ec2" {
  security_group_id = aws_security_group.ec2_security_group.id
  description       = "Allow HTTP traffic from CloudFront to application services running in k8s pods"
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 30001
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

# Outbound rules (allow all outbound traffic)
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.ec2_security_group.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}