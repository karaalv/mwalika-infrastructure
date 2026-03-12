variable "aws_region" {
  description = "The AWS region where the S3 bucket and DynamoDB table for Terraform state will be created."
  type        = string
  default     = "af-south-1"
}