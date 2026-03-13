# The elastic IP for the EC2 instance must be
# output in order for it to be used in the
# MongoDB Atlas configuration for IP access control.

output "production_ec2_elastic_ip" {
  value = aws_eip.ec2_elastic_ip.public_ip
}

output "github_actions_role_arn" {
  description = "IAM role ARN used by GitHub Actions OIDC"
  value       = aws_iam_role.github_actions_role.arn
}
